class Organization < ActiveRecord::Base
  unloadable
  acts_as_nested_set

  validates_presence_of :name
  validates :name, :uniqueness => {:scope => :parent_id}
  validates_format_of :mail, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :allow_blank => true

  has_many :users
  has_many :organization_roles

  SEPARATOR = '/'

  # Reorder tree after save on the fly
  # Less beautiful than Redmine method to keep tree sorted,
  # But also far less complicated
  after_save do |org|
    siblings = org.siblings
    while org.left_sibling && org.left_sibling.name > org.name
      org.move_left
    end
  end
  
  def <=>(other)
    other.name.casecmp(self.name)
  end
  
  def name
    read_attribute(:name) || ""
  end
  
  def fullname
    @fullname ||= ancestors.all(:order => 'lft').map do |ancestor|
      ancestor.name+Organization::SEPARATOR
    end.join("") + name
  end

  def direction_organization
    @direction_organization ||= (direction? || root? ? self : parent.direction_organization)
  end

  def memberships
    Member.joins(:user).where("users.organization_id = ?", self.id)
  end

  def projects
    Project.where("id IN (?)", self.memberships.pluck(:project_id).uniq)
  end

  def roles_by_project(project)
    Role.joins(:member_roles => :member).where("user_id IN (?) AND project_id = ?", self.users.map(&:id), project.id).uniq
  end

  def default_roles_by_project(project)
    organization_roles.where("project_id = ?", project.id).map(&:role).uniq
  end

  # Yields the given block for each organization with its level in the tree
  def self.organization_tree(organizations, &block)
    ancestors = []
    organizations.sort_by(&:lft).each do |organization|
      while (ancestors.any? && !organization.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield organization, ancestors.size
      ancestors << organization
    end
  end

  def update_project_members(project_id, new_members, new_roles, old_organization_roles)
    delete_old_project_members(project_id, new_members)

    new_members.each do |user|
      add_member_through_organization(user, project_id, new_roles, old_organization_roles)
    end if new_roles.present?
  end

  def delete_old_project_members(project_id, excluded = [])
    current_members = User.joins(:members).where("organization_id = ? AND project_id = ?", self.id, project_id).uniq
    current_members.each do |user|
      next if excluded.include?(user)
      user.destroy_membership_through_organization(project_id)
    end
  end

  def delete_all_organization_roles(project_id, excluded = [])
    organization_roles.where(project_id: project_id).each do |r|
      next if excluded.include?(r)
      r.try(:destroy) if r.id
    end
  end

  private

    def add_member_through_organization(user, project_id, new_roles, old_organization_roles)
      member = Member.where(user_id: user.id, project_id: project_id).first_or_initialize
      old_personal_roles = member.roles - old_organization_roles
      member.roles = []
      (new_roles | old_personal_roles).each do |new_role|
        unless member.roles.include?(new_role)
          member.roles << new_role
        end
      end
      member.save! if member.project.present? && member.user.present?
    end

end

class Organization < ActiveRecord::Base
  include Redmine::SafeAttributes

  acts_as_nested_set

  validates_presence_of :name
  validates :name, :uniqueness => {:scope => :parent_id}
  validates_format_of :mail, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, :allow_blank => true

  has_many :users
  has_many :organization_roles
  has_many :organization_managers
  has_many :organization_team_leaders
  has_many :managers, through: :organization_managers, :source => :user
  has_many :team_leaders, through: :organization_team_leaders, :source => :user
  has_many :organization_notifications
  has_many :notified_projects, through: :organization_notifications, :source => :project

  safe_attributes :name, :parent_id, :description, :mail, :direction, :name_with_parents, :notified

  before_validation :update_name_with_parents

  SEPARATOR = '/'

  scope :sorted, -> { order('lft') }
  scope :direction, -> { where(direction: true) }

  # Reorder tree after save on the fly
  # Less beautiful than Redmine method to keep tree sorted,
  # But also far less complicated
  after_save do |org|
    siblings = org.siblings
    while org.left_sibling && org.left_sibling.name > org.name
      org.move_left
    end
  end

  def update_name_with_parents
    self.name_with_parents = calculated_fullname
    self.identifier = calculated_identifier
  end

  def <=>(other)
    other.name.casecmp(self.name)
  end

  def name
    read_attribute(:name) || ""
  end

  def fullname
    if read_attribute(:name_with_parents).blank?
      calculated_fullname
    else
      read_attribute(:name_with_parents)
    end
  end

  def calculated_fullname
    if parent_id.present?
      Organization.find(parent_id).fullname + Organization::SEPARATOR + name
    else
      name
    end
  end

  def to_s
    fullname
  end

  def calculated_identifier
    name_with_parents.parameterize
  end

  def direction_organization
    @direction_organization ||= (direction? || root? ? self : parent.direction_organization)
  end

  def root_direction_organization
    self_and_ancestors.where(direction: true).first
  end

  def memberships
    Member.joins(:user).where("users.organization_id = ? AND users.status = ?", self.id, User::STATUS_ACTIVE)
  end

  def users_by_project(project)
    users.joins(:members).where("users.status = ? AND members.project_id = ?", User::STATUS_ACTIVE, project.id)
  end

  def projects
    Project.where("id IN (?)", self.memberships.pluck(:project_id).uniq)
  end

  def roles_by_project(project)
    Role.joins(:member_roles => :member).where("user_id IN (?) AND project_id = ?", self.users.active.map(&:id), project.id).uniq
  end

  def default_roles_by_project(project)
    organization_roles.for_project(project).includes(:role).map(&:role).compact.sort_by { |r| "#{r.position.to_s.rjust(5, '0')}-#{r.id}" }
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

  def delete_old_project_members(project_id, excluded = [])
    current_members = User.joins(:members).where("organization_id = ? AND project_id = ?", self.id, project_id).uniq
    current_members.each do |user|
      next if excluded.include?(user)
      user.destroy_membership_through_organization(project_id)
    end
  end

  def delete_all_organization_roles(project_id, excluded_roles = [])
    organization_roles.where(project_id: project_id).where.not(role_id: excluded_roles.map(&:id)).each do |organization_role|
      organization_role.try(:destroy) if organization_role.id
    end
  end

  def all_managers
    managers + inherited_managers
  end

  def inherited_managers
    self.ancestors.map(&:managers).flatten.uniq
  end

  def all_team_leaders
    team_leaders + inherited_team_leaders
  end

  def inherited_team_leaders
    self.ancestors.map(&:team_leaders).flatten.uniq
  end

  def self.managed_by(user:)
    Organization.joins(:organization_managers).where("organization_managers.user_id = ?", user.id).order('lft').map(&:self_and_descendants).flatten.uniq
  end

end

class OrganizationMembership < ActiveRecord::Base
  belongs_to :organization
  belongs_to :project

  validates_presence_of :organization, :project
  validates_uniqueness_of :organization_id, :scope => :project_id

  after_destroy :delete_old_members

  def roles
    Role.joins(:member_roles => :member).where("user_id IN (?) AND project_id = ?", self.users.map(&:id), self.project.id)
  end

  def users
    User.member_of(self.project).where("organization_id = ?", self.organization_id)
  end

  def self.add_member(user, project_id, role_ids)
    member = Member.where(user_id: user.id, project_id: project_id).first_or_initialize
    role_ids.each do |new_role_id|
      unless member.roles.map(&:id).include?(new_role_id)
        member.roles << Role.find(new_role_id)
      end
    end
    member.save! if member.project.present? && member.user.present?
  end

  def delete_old_members(excluded = [])
    OrganizationMembership.delete_old_members(organization_id, project_id, excluded)
  end

  def self.delete_old_members(organization_id, project_id, excluded = [])
    members = User.joins(:members).where("organization_id = ? AND project_id = ?", organization_id, project_id).uniq
    members.each do |user|
      next if excluded.include?(user.id)
      user.destroy_membership_through_organization(project_id)
    end
  end

end

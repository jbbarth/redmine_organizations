class OrganizationMembership < ActiveRecord::Base
  belongs_to :organization
  belongs_to :project
  has_many :organization_roles, :dependent => :destroy
  has_many :roles, :through => :organization_roles

  validates_presence_of :organization, :project
  validates_uniqueness_of :organization_id, :scope => :project_id

  after_save :update_users_memberships
  after_destroy :delete_old_members

  def users
    User.member_of(self.project).where("organization_id = ?", self.organization_id)
  end

  def update_users_memberships
    #update users roles
    self.users.each do |user|
      user.update_membership_through_organization(self)
    end
    #delete old involvements/memberships
    (self.organization.users - self.users).each do |user|
      user.destroy_membership_through_organization(self)
    end
    #delete old involvements/memberships for deleted users
    if @old_user_ids.present?
      (@old_user_ids - self.user_ids).each do |user_id|
        user = User.find(user_id)
        user.destroy_membership_through_organization(self)
      end
    end
  end

  def delete_old_members(excluded = [])
    self.users.each do |user|
      next if excluded.include?(user.id)
      user.destroy_membership_through_organization(self)
    end
  end

  def user_ids=(*args)
    @old_user_ids = self.user_ids
    super
  end
end

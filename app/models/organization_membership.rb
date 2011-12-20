class OrganizationMembership < ActiveRecord::Base
  belongs_to :organization
  belongs_to :project
  has_many :organization_roles, :dependent => :destroy
  has_many :roles, :through => :organization_roles
  has_many :organization_involvements
  has_many :users, :through => :organization_involvements
  
  validates_presence_of :organization, :project
  validates_uniqueness_of :organization_id, :scope => :project_id
  
  after_save :update_users_memberships
  after_destroy :delete_old_members
  
  def update_users_memberships
    #update users roles
    self.users.each do |user|
      user.update_membership_through_organization(self)
    end
    #delete old involvements
    (self.organization.users - self.users).each do |user|
      user.destroy_membership_through_organization(self)
    end
  end

  def delete_old_members(excluded = [])
    self.users.each do |user|
      next if excluded.include?(user.id)
      user.destroy_membership_through_organization(self)
    end
  end

  def user_ids=(values)
    delete_old_members(values)
    write_attribute(:user_ids, values)
  end
end

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
  
  def update_users_memberships
    #update users roles
    self.users.each do |user|
      attributes = {:user_id => user.id, :project_id => self.project_id}
      member = Member.first(:conditions => attributes) || Member.new(attributes)
      member.roles = self.roles + user.roles_through_involvements(self.project_id, self.id)
      member.save
    end
    #delete old involvements
    (self.organization.users - self.users).each do |user|
      attributes = {:user_id => user.id, :project_id => self.project_id}
      if member = Member.first(:conditions => attributes).try(:destroy)
        member.roles = user.roles_through_involvements(self.project_id, self.id)
        if member.roles.blank?
          member.destroy
        else
          member.save
        end
      end
    end
  end
end

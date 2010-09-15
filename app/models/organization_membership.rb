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
      attributes = {:user_id => user, :project_id => self.project_id}
      member = Member.first(:conditions => attributes) || Member.new(attributes)
      member.roles = self.roles
      member.save
    end
    #delete old involvements
    (self.organization.users - self.users).each do |user|
      attributes = {:user_id => user, :project_id => self.project}
      Member.first(:conditions => attributes).try(:destroy)
    end
  end
end

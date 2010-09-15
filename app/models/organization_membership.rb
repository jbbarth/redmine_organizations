class OrganizationMembership < ActiveRecord::Base
  belongs_to :organization
  belongs_to :project
  has_many :organization_roles, :dependent => :destroy
  has_many :roles, :through => :organization_roles
  has_many :organization_involvements
  has_many :users, :through => :organization_involvements
  
  validates_presence_of :organization, :project
  validates_uniqueness_of :organization_id, :scope => :project_id
end

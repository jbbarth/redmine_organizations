class OrganizationMembership < ActiveRecord::Base
  belongs_to :organization
  belongs_to :project
  has_many :organization_roles, :dependent => :destroy
  has_many :roles, :through => :organization_roles
  
  validates_presence_of :organization, :project
  validates_uniqueness_of :organization_id, :scope => :project_id
end

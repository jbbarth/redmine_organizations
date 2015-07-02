class OrganizationRole < ActiveRecord::Base
  belongs_to :project
  belongs_to :organization
  belongs_to :role
  validates_uniqueness_of :role_id, scope: [:project_id, :organization_id]
  validates_presence_of :role_id, :project_id, :organization_id

  attr_accessible :role_id, :project_id
end

class OrganizationRole < ApplicationRecord
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :organization
  belongs_to :role
  validates_uniqueness_of :role_id, scope: [:project_id, :organization_id]
  validates_presence_of :role_id, :project_id, :organization_id

  safe_attributes :role_id, :project_id, :organization_id, :non_member_role

  scope :for_project, ->(project) { where("organization_roles.project_id = ?", project.id) if project.present? }

end

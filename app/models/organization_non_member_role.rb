class OrganizationNonMemberRole < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :organization
  belongs_to :role
  validates_uniqueness_of :role_id, scope: [:project_id, :organization_id]
  validates_presence_of :role_id, :project_id, :organization_id

  safe_attributes :role_id, :project_id, :organization_id

  scope :for_project, ->(project) { where("organization_non_member_roles.project_id IN (?)", project.self_and_ancestors.ids) if project.present? }

end

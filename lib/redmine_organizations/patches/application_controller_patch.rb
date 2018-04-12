require_dependency 'application_controller'

module PluginOrganizations
  module ApplicationController

    def authorize(ctrl = params[:controller], action = params[:action], global = false)
      if @project.present?
        user_organization = User.current.try(:organization)
        user_organization_and_parents_ids = user_organization.self_and_ancestors.map(&:id) if user_organization.present?
        organization_roles = OrganizationRole.where(project_id: @project.id, organization_id: user_organization_and_parents_ids, non_member_role: true)
      end
      if organization_roles.present?
        true
      else
        super
      end
    end

  end
end

ApplicationController.prepend PluginOrganizations::ApplicationController

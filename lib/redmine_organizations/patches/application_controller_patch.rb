require_dependency 'application_controller'

class ApplicationController < ActionController::Base

  unless instance_methods.include?(:authorize_with_organization_exceptions)
    def authorize_with_organization_exceptions(ctrl = params[:controller], action = params[:action], global = false)
      if @project.present?
        user_organization = User.current.try(:organization)
        user_organization_and_parents_ids = user_organization.self_and_ancestors.map(&:id) if user_organization.present?
        organization_roles = OrganizationRole.where(project_id: @project.id, organization_id: user_organization_and_parents_ids, non_member_role: true)
      end
      if organization_roles.present?
        true
      else
        authorize_without_organization_exceptions(ctrl, action, global)
      end
    end
    alias_method_chain :authorize, :organization_exceptions
  end

end

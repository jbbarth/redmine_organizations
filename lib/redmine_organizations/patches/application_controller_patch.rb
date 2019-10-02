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

    def find_organization_by_id
      @organization = Organization.where("identifier = lower(?) OR id = ?", params[:id], params[:id].to_i).first
      render_404 if @organization.blank?
    end

    def require_admin_or_manager
      return unless require_login
      if @organization.present?
        managers_user_ids = OrganizationManager
                                .where("organization_id IN (?)", @organization.self_and_ancestors.map(&:id))
                                .pluck(:user_id)
      else
        managers_user_ids = OrganizationManager.pluck(:user_id)
      end
      if managers_user_ids.exclude?(User.current.id) && User.current.is_not_admin?
        render_403
        return false
      end
      true
    end

  end
end

ApplicationController.prepend PluginOrganizations::ApplicationController

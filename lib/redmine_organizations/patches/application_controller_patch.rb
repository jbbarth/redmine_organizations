require_dependency 'application_controller'

module RedmineOrganizations::Patches
  module ApplicationControllerPatch

    def authorize(ctrl = params[:controller], action = params[:action], global = false)
      if @project.present? && User.current.try(:organization).present?
        user_organization_and_parents_ids = User.current.organization.self_and_ancestors_ids
        project_and_parents_ids = @project.self_and_ancestors.ids
        organization_roles = OrganizationNonMemberRole.where(project_id: project_and_parents_ids, organization_id: user_organization_and_parents_ids)
      end
      if organization_roles.present?
        true
      else
        super
      end
    end

    def find_organization_by_id
      if params[:id].to_i.to_s == params[:id].to_s
        @organization = Organization.where(id: params[:id]).first
      else
        @organization = Organization.where(identifier: params[:id].to_s.parameterize).first
      end
      render_404 if @organization.blank?
    end

    def require_admin_or_manager

      return unless require_login
      return true if User.current.is_admin_or_instance_manager?

      if @organization.present?
        managers_user_ids = OrganizationManager.where("organization_id IN (?)", @organization.self_and_ancestors.map(&:id))
                                               .pluck(:user_id)
      else
        managers_user_ids = OrganizationManager.pluck(:user_id)
      end
      if managers_user_ids.exclude?(User.current.id)
        render_403
      else
        true
      end

    end

  end
end

ApplicationController.prepend RedmineOrganizations::Patches::ApplicationControllerPatch

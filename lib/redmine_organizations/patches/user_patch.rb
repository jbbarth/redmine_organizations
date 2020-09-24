# require_dependency 'project' #see: http://www.redmine.org/issues/11035
require_dependency 'principal'
require_dependency 'user'

#Here's a hack to avoid User class missing Principal scopes
#TODO: find a better hack...
#TODO: confirm the bug is gone in rails 3
#User.scopes[:like] = Principal.scopes[:like]

class User < Principal
  belongs_to :organization
  has_many :organization_managers
  has_many :organization_team_leaders

  safe_attributes('organization_id',
      :if => lambda {|user, current_user| current_user.admin?})

  attr_accessor :orga_update_method

  def destroy_membership_through_organization(project_id)
    if id
      attributes = {:user_id => id, :project_id => project_id}
      Member.where(attributes).first.try(:destroy)
    end
  end

  def is_admin_or_manage?(organization)
    admin? || is_a_manager?(organization)
  end

  def manage_his_organization?
    organization.managers.include?(self)
  end

  def is_a_manager?(organization)
    OrganizationManager.where(organization: organization.self_and_ancestors).pluck(:user_id).include?(self.id)
  end

  def is_not_admin?
    !admin?
  end

  def managers
    if self.organization.present?
      organization.all_managers
    else
      []
    end
  end

  # Returns the roles that the user is allowed to manage for the given project
  def managed_organizations(project)
    if admin?
      Organization.all
    else
      membership(project).try(:managed_organizations) || []
    end
  end

  def managed_only_his_organization?(project)
    if admin?
      false
    else
      membership(project).try(:managed_only_his_organization?)
    end
  end

end



module PluginOrganizations
  module UserModel

    # with organization exceptions TODO Test it
    #
    # Return true if the user is allowed to do the specified action on a specific context
    # Action can be:
    # * a parameter-like Hash (eg. :controller => 'projects', :action => 'edit')
    # * a permission Symbol (eg. :edit_project)
    # Context can be:
    # * a project : returns true if user is allowed to do the specified action on this project
    # * an array of projects : returns true if user is allowed on every project
    # * nil with options[:global] set : check if user has at least one role allowed for this action,
    #   or falls back to Non Member / Anonymous permissions depending if the user is logged
    def allowed_to?(action, context, options={}, &block)

      if context && context.is_a?(Project)
        return false unless context.allows_to?(action)
        # Admin users are authorized for anything else
        return true if admin?

        roles = roles_for_project(context)

        ## START PATCH
        user_organization = User.current.try(:organization)
        user_organization_and_parents_ids = user_organization.self_and_ancestors.map(&:id) if user_organization.present?
        organization_roles = OrganizationRole.where(project_id: context.id, organization_id: user_organization_and_parents_ids, non_member_role: true)
        roles += organization_roles.map(&:role) if organization_roles.present?
        ## END PATCH

        return false unless roles
        roles.any? {|role|
          (context.is_public? || role.member?) &&
              role.allowed_to?(action) &&
              (block_given? ? yield(role, self) : true)
        }
      elsif context && context.is_a?(Array)
        if context.empty?
          false
        else
          # Authorize if user is authorized on every element of the array
          context.map {|project| allowed_to?(action, project, options, &block)}.reduce(:&)
        end
      elsif context
        raise ArgumentError.new("#allowed_to? context argument must be a Project, an Array of projects or nil")
      elsif options[:global]
        # Admin users are always authorized
        return true if admin?

        # authorize if user has at least one role that has this permission
        roles = self.roles.to_a | [builtin_role] | Group.non_member.roles.to_a | Group.anonymous.roles.to_a

        ## START PATCH
        user_organization = User.current.try(:organization)
        user_organization_and_parents_ids = user_organization.self_and_ancestors.map(&:id) if user_organization.present?
        organization_roles = OrganizationRole.where(organization_id: user_organization_and_parents_ids, non_member_role: true)
        roles += organization_roles.map(&:role) if organization_roles.present?
        ## END PATCH

        roles.any? {|role|
          role.allowed_to?(action) &&
              (block_given? ? yield(role, self) : true)
        }
      else
        super
      end
    end
  end
end
User.prepend PluginOrganizations::UserModel

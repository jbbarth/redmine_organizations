# require_dependency 'project' #see: http://www.redmine.org/issues/11035
require_dependency 'principal'
require_dependency 'user'

#Here's a hack to avoid User class missing Principal scopes
#TODO: find a better hack...
#TODO: confirm the bug is gone in rails 3
#User.scopes[:like] = Principal.scopes[:like]

class User < Principal
  unloadable
  belongs_to :organization
  has_many :organization_managers
  has_many :organization_team_leaders

  safe_attributes 'organization_id'
  attr_accessor :org_update_method

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

# with organization exceptions TODO Test it
module PluginOrganizations
  module UserModel
    def allowed_to?(action, context, options = {}, &block)
      if context && context.is_a?(Project)
        return false unless context.allows_to?(action)
        # Admin users are authorized for anything else
        return true if admin?

        roles = roles_for_project(context)

        user_organization = User.current.try(:organization)
        user_organization_and_parents_ids = user_organization.self_and_ancestors.map(&:id) if user_organization.present?
        organization_roles = OrganizationRole.where(project_id: context.id, organization_id: user_organization_and_parents_ids, non_member_role: true)
        roles += organization_roles.map(&:role) if organization_roles.present?

        return false unless roles
        roles.any? {|role|
          (context.is_public? || role.member?) &&
              role.allowed_to?(action) &&
              (block_given? ? yield(role, self) : true)
        }
      elsif context == nil && options[:global]
        # Admin users are always authorized
        return true if admin?

        # authorize if user has at least one role that has this permission
        roles = memberships.includes(:roles).collect {|m| m.roles}.flatten.uniq
        roles << (self.logged? ? Role.non_member : Role.anonymous)

        user_organization = User.current.try(:organization)
        user_organization_and_parents_ids = user_organization.self_and_ancestors.map(&:id) if user_organization.present?
        organization_roles = OrganizationRole.where(organization_id: user_organization_and_parents_ids, non_member_role: true)
        roles += organization_roles.map(&:role) if organization_roles.present?

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

# require_dependency 'project' #see: http://www.redmine.org/issues/11035
require_dependency 'principal'
require_dependency 'user'

# Here's a hack to avoid User class missing Principal scopes
# TODO: find a better hack...
# TODO: confirm the bug is gone in rails 3
# User.scopes[:like] = Principal.scopes[:like]

class User < Principal
  belongs_to :organization, counter_cache: true
  has_many :organization_managers, :dependent => :destroy
  has_many :organization_team_leaders, :dependent => :destroy

  scope :team_leader, -> { joins(:organization_team_leaders) }

  safe_attributes('organization_id',
                  :if => lambda { |user, current_user| current_user.is_admin_or_instance_manager? })

  attr_accessor :orga_update_method

  def destroy_membership_through_organization(project_id)
    if id
      attributes = { :user_id => id, :project_id => project_id }
      Member.where(attributes).first.try(:destroy)
    end
  end

  def is_admin_or_manage?(organization)
    is_admin_or_instance_manager? || is_a_manager?(organization)
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

  def is_admin_or_instance_manager?
    admin? || (self.try(:instance_manager) == true)
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
    if is_admin_or_instance_manager?
      Organization.all
    else
      membership(project).try(:managed_organizations) || []
    end
  end

  def managed_only_his_organization?(project)
    if is_admin_or_instance_manager?
      false
    else
      membership(project).try(:managed_only_his_organization?)
    end
  end

end

module RedmineOrganizations::Patches::UserPatch

  # Return user's roles for project
  def roles_for_project(project)
    # No role on archived projects
    return [] if project.nil? || project.archived?

    roles = super
    if self.organization.present?
      roles |= self.organization.organization_non_member_roles_for_project(project)
    end
    roles
  end

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
  def allowed_to?(action, context, options = {}, &block)
    if options[:global] && context.blank?
      # Admin users are always authorized
      return true if admin?

      # authorize if user has at least one role that has this permission
      roles = self.roles.to_a | [builtin_role] | Group.non_member.roles.to_a | Group.anonymous.roles.to_a

      ## START PATCH
      user_organization = User.current.try(:organization)
      if user_organization.present?
        user_organization_and_parents_ids = user_organization.self_and_ancestors_ids
        organization_roles = Role.distinct.joins(:organization_non_member_roles).where("organization_id IN (?)", user_organization_and_parents_ids)
        roles |= organization_roles
      end
      ## END PATCH

      roles.any? do |role|

        # Keep compatibility with Redmine 6.0 and previous versions
        if Redmine::VERSION::MAJOR >= 6 && Redmine::VERSION::MINOR >= 1
          role.allowed_to?(action, @oauth_scope) &&
            (block ? yield(role, self) : true)
        else
          role.allowed_to?(action) &&
            (block ? yield(role, self) : true)
        end

      end
    else
      super
    end
  end
end

User.prepend RedmineOrganizations::Patches::UserPatch

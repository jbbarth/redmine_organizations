require_dependency 'member'

module RedmineOrganizations::Patches::MemberPatch

  # Set member role ids ignoring any change to roles that
  # user is not allowed to manage
  def set_editable_role_ids(ids, user = User.current)
    ids = (ids || []).collect(&:to_i) - [0]
    editable_role_ids = user.managed_roles(project).map(&:id)
    untouched_role_ids = self.role_ids - editable_role_ids
    touched_role_ids = ids & editable_role_ids

    ### PATCH: Add organization roles
    if self.principal && principal.is_a?(User) && self.principal.organization
      organization_role_ids = self.principal.organization.default_roles_by_project(self.project).map(&:id)
      self.role_ids = untouched_role_ids | touched_role_ids | organization_role_ids
    else
      self.role_ids = untouched_role_ids + touched_role_ids
    end

  end

  # Returns the organizations that the member is allowed to manage
  # in the project the member belongs to
  def managed_organizations
    if principal.try(:is_admin_or_instance_manager?)
      Organization.all
    else
      members_management_roles = roles.select do |role|
        role.has_permission?(:manage_members)
      end
      if members_management_roles.empty?
        []
      elsif members_management_roles.any?(&:all_organizations_managed?)
        Organization.all
      else
        if principal.try(:organization)
          principal.organization.self_and_descendants
        else
          []
        end
      end
    end
  end

  def managed_only_his_organization?
    if principal.try(:is_admin_or_instance_manager?)
      false
    else
      members_management_roles = roles.select do |role|
        role.has_permission?(:manage_members)
      end
      if members_management_roles.empty?
        false
      elsif members_management_roles.any?(&:all_organizations_managed?)
        false
      else
        true
      end
    end
  end

end

Member.prepend RedmineOrganizations::Patches::MemberPatch

require_dependency 'member'

class Member

  # Set member role ids ignoring any change to roles that
  # user is not allowed to manage
  def set_editable_role_ids(ids, user=User.current)
    ids = (ids || []).collect(&:to_i) - [0]
    editable_role_ids = user.managed_roles(project).map(&:id)
    ### PATCH: Add organization roles
    organization_role_ids = self.principal.organization ? self.principal.organization.default_roles_by_project(self.project).map(&:id) : []
    untouched_role_ids = self.role_ids - editable_role_ids
    touched_role_ids = ids & editable_role_ids
    self.role_ids = untouched_role_ids | touched_role_ids | organization_role_ids
  end

end

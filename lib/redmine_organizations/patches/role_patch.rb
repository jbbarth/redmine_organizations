require_dependency "role"

module RedmineOrganizations::Patches::RolePatch

end

class Role
  has_many :organization_roles, :dependent => :destroy
  has_many :organization_non_member_roles, :dependent => :destroy
end

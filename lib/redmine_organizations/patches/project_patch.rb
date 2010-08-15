require_dependency 'project'

class Project
  unloadable
  has_many :organization_memberships
  has_many :organizations, :through => :organization_memberships
end

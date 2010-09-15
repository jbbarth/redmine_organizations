require_dependency 'principal'
require_dependency 'user'

class User < Principal
  unloadable
  has_many :organization_users
  has_many :organizations, :through => :organization_users
  has_many :organization_involvements
end

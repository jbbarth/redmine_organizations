require_dependency 'principal'
require_dependency 'user'

class User < Principal
  unloadable
  has_many :organization_users
  has_many :organizations, :through => :organization_users
  has_many :organization_involvements
  
  def roles_through_involvements(project_id, excluded_organization_id)
    m = OrganizationMembership.all(:joins => [:users,:roles],
                                   :conditions => ["organization_memberships.id != ? AND project_id = ? AND users.id = ?",
                                                   excluded_organization_id, project_id, self.id])
    m.map(&:roles).flatten.uniq
  end
end

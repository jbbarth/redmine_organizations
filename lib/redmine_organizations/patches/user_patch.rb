require_dependency 'project' #see: http://www.redmine.org/issues/11035
require_dependency 'principal'
require_dependency 'user'

#Here's a hack to avoid User class missing Principal scopes
#TODO: find a better hack...
#TODO: confirm the bug is gone in rails 3
#User.scopes[:like] = Principal.scopes[:like]

class User < Principal
  unloadable
  belongs_to :organization

  safe_attributes 'organization_id'
  
  def roles_through_involvements(project_id, excluded_organization_id)
    m = OrganizationMembership.all(:joins => [:users,:roles],
                                   :conditions => ["organization_memberships.id != ? AND project_id = ? AND users.id = ?",
                                                   excluded_organization_id, project_id, self.id])
    m.map(&:roles).flatten.uniq
  end

  def update_membership_through_organization(organization_membership)
    if id && project_id = organization_membership.project_id
      attributes = {:user_id => id, :project_id => project_id}
      member = Member.first(:conditions => attributes) || Member.new(attributes)
      member.roles = organization_membership.roles
      member.save!
    end
  end
  
  def destroy_membership_through_organization(organization_membership)
    if id && project_id = organization_membership.project_id
      attributes = {:user_id => id, :project_id => project_id}
      Member.first(:conditions => attributes).try(:destroy)
    end
  end
end

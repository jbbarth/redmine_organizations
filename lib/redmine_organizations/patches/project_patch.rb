require_dependency 'project'

class Project
  unloadable
  has_many :organization_memberships
  has_many :organizations, :through => :organization_memberships
  
  def users_by_role_and_organization
    #{user1=>org1,user2=>org2,user3=>org1}
    org_users = organizations.all(:include => :users).inject({}) do |h,o|
      o.user_ids.each do |u|
        h[u] = o unless h[u]
      end
      h
    end
    members.find(:all, :include => [:user, :roles]).inject({}) do |h, m|
      m.roles.each do |r|
        #don't register user if he's not
        #part of a registered organization
        if ou = org_users[m.user_id]
          h[r] ||= {}
          h[r][ou] ||= []
          h[r][org_users[m.user_id]] << m.user
        end
      end
      h
    end
  end
end

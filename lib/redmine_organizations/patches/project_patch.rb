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
    #{org1=>[user1,user2],org2=>[],?=>[user3]}
    dummy_org = Organization.new(:name => l(:label_others))
    members.find(:all, :include => [:user, :roles]).inject({}) do |h, m|
      m.roles.each do |r|
        next if r.hidden_on_overview?
        ou = org_users[m.user_id] || dummy_org
        h[r] ||= {}
        h[r][ou] ||= []
        h[r][ou] << m.user
      end
      h
    end
  end
end

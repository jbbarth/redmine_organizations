require_dependency 'project'

class Project
  unloadable

  def organizations
    Organization.joins(:users => :members).where("project_id = ?", self.id).uniq
  end

  # Builds a nested hash of users sorted by role and organization
  # => { Role(1) => { Org(1) => [ User(1), User(2), ... ] } }
  #
  # TODO: simplify / refactor / test it correctly !!!
  def users_by_role_and_organization
    dummy_org = Organization.new(:name => l(:label_others))
    self.members.map do |member|
      member.roles.map do |role|
        { :user => member.user, :role => role, :organization => member.user.organization }
      end
    end.flatten.group_by do |hsh|
      hsh[:role]
    end.inject({}) do |memo, (role, users)|
      if role.hidden_on_overview?
        #do nothing
        memo
      else
        #build a hash for that role
        hsh = users.group_by do |user|
          user[:organization] || dummy_org
        end
        hsh.each do |org, users_hsh|
          hsh[org] = users_hsh.map{|h| h[:user]}.sort
        end
        memo[role] = hsh
        memo
      end
    end
  end
end

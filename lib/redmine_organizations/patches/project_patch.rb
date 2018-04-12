require_dependency 'project'

class Project
  unloadable

  has_many :organization_roles

  safe_attributes "notify_organizations"

  def organizations
    Organization.joins(:users => :members).where("project_id = ? AND users.status = ?", self.id, User::STATUS_ACTIVE).uniq
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

# TODO Test it
module PluginOrganizations
  module ProjectModel
    # Returns true if usr or current user is allowed to view the issue with_organization_exceptions
    def allowed_to_condition(user, permission, options={}, &block)
      user_organization = user.try(:organization)
      user_organization_and_parents_ids = user_organization.self_and_ancestors.map(&:id) if user_organization.present?
      organization_roles = OrganizationRole.where(organization_id: user_organization_and_parents_ids, non_member_role: true)

      allowed_projects_ids = []
      organization_roles.each do |organization_role|
        if organization_role.role.allowed_to?(permission)
          allowed_projects_ids << organization_role.project_id
        end
      end

      custom_statement = allowed_projects_ids.present? ? "(#{Project.table_name}.id IN (#{allowed_projects_ids.join(',')}))" : "1=0"
      standard_statement = super

      "(#{standard_statement} OR #{custom_statement})"
    end
  end
end
Project.singleton_class.prepend PluginOrganizations::ProjectModel

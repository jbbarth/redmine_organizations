require_dependency 'project'
require_dependency 'principal'
require_dependency 'user'

class Project < ActiveRecord::Base

  has_many :organization_roles, :dependent => :destroy
  has_many :organization_notifications
  has_many :notified_organizations, through: :organization_notifications, :source => :organization

  def organizations
    Organization.joins(:users => :members).where("project_id = ? AND users.status = ?", self.id, User::STATUS_ACTIVE).uniq
  end

  # Returns a SQL conditions string used to find all projects for which +user+ has the given +permission+
  #
  # Valid options:
  # * :skip_pre_condition => true       don't check that the module is enabled (eg. when the condition is already set elsewhere in the query)
  # * :project => project               limit the condition to project
  # * :with_subprojects => true         limit the condition to project and its subprojects
  # * :member => true                   limit the condition to the user projects
  def self.allowed_to_condition(user, permission, options={})
    perm = Redmine::AccessControl.permission(permission)
    base_statement =
      if perm && perm.read?
        "#{Project.table_name}.status <> #{Project::STATUS_ARCHIVED}"
      else
        "#{Project.table_name}.status = #{Project::STATUS_ACTIVE}"
      end
    if !options[:skip_pre_condition] && perm && perm.project_module
      # If the permission belongs to a project module, make sure the module is enabled
      base_statement +=
        " AND EXISTS (SELECT 1 AS one FROM #{EnabledModule.table_name} em" \
          " WHERE em.project_id = #{Project.table_name}.id" \
          " AND em.name='#{perm.project_module}')"
    end
    if project = options[:project]
      project_statement = project.project_condition(options[:with_subprojects])
      base_statement = "(#{project_statement}) AND (#{base_statement})"
    end

    if user.admin?
      base_statement
    else
      statement_by_role = {}
      unless options[:member]
        role = user.builtin_role
        if role.allowed_to?(permission)
          s = "#{Project.table_name}.is_public = #{connection.quoted_true}"
          if user.id
            group = role.anonymous? ? Group.anonymous : Group.non_member
            principal_ids = [user.id, group.id].compact
            s =
              "(#{s} AND #{Project.table_name}.id NOT IN " \
                "(SELECT project_id FROM #{Member.table_name} " \
                "WHERE user_id IN (#{principal_ids.join(',')})))"
          end
          statement_by_role[role] = s
        end
      end
      user.project_ids_by_role.each do |role, project_ids|
        if role.allowed_to?(permission) && project_ids.any?
          statement_by_role[role] = "#{Project.table_name}.id IN (#{project_ids.join(',')})"
        end
      end

      ### START PATCH FOR NON-MEMBER EXCEPTIONS BY ORGANIZATION ###
      if user.organization.present?
        non_member_organization_statements = []
        OrganizationNonMemberRole.where(organization_id: user.organization.self_and_ancestors_ids)
                                 .includes(:project).each do |non_member_role|
          non_member_organization_statements << "(#{Project.table_name}.lft >= #{non_member_role.project.lft} AND #{Project.table_name}.rgt <= #{non_member_role.project.rgt})"
        end
      end

      if statement_by_role.empty? && non_member_organization_statements.blank?
        "1=0"
      else
        if block_given?
          statement_by_role.each do |role, statement|
            if s = yield(role, user)
              statement_by_role[role] = "(#{statement} AND (#{s}))"
            end
          end
        end
        if non_member_organization_statements.present?
          statements_by_role = statement_by_role.values + non_member_organization_statements
          "((#{base_statement}) AND (#{statements_by_role.join(' OR ')}))"
        else
          "((#{base_statement}) AND (#{statement_by_role.values.join(' OR ')}))"
        end
      end

      ### END PATCH FOR NON-MEMBER EXCEPTIONS BY ORGANIZATION ###
    end
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
          hsh[org] = users_hsh.map { |h| h[:user] }.sort
        end
        memo[role] = hsh
        memo
      end
    end
  end
end

# TODO Test it
module PluginOrganizations

  module CopyProjectModel
    #Copies organizations_roles from +project+
    def copy_organizations_roles(project)
      orga_roles_to_copy = project.organization_roles
      orga_roles_to_copy.each do |orga_role|
        new_orga_role = OrganizationRole.new
        new_orga_role.attributes = orga_role.attributes.dup.except("id", "project_id")
        self.organization_roles << new_orga_role
      end
    end

    def copy(project, options = {})
      super
      project = project.is_a?(Project) ? project : Project.find(project)

      to_be_copied = %w(organizations_roles)

      to_be_copied = to_be_copied & Array.wrap(options[:only]) unless options[:only].nil?

      Project.transaction do
        if save
          reload

          to_be_copied.each do |name|
            send "copy_#{name}", project
          end

          save
        else
          false
        end
      end
    end
  end
end

Project.prepend PluginOrganizations::CopyProjectModel

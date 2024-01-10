require_dependency 'issue_query'

class IssueQuery < Query
  self.available_columns << QueryColumn.new(:author_organization, :groupable => false) if self.available_columns.select { |c| c.name == :author_organization }.empty?
end

module PluginOrganizations

  module IssueQueryPatch

    # Returns the issues
    # Valid options are :order, :offset, :limit, :include, :conditions
    def issues(options={})
      issues = super
      if has_column?(:author_organization)
        Issue.load_author_organization(issues)
      end
      issues
    end

    def initialize_available_filters
      super
      add_available_filter "author_organization",
                           :type => :list_optional,
                           :values => lambda {organization_values},
                           :label => :field_author_organization
      add_available_filter "updated_by_organization",
                           :type => :list_optional,
                           :values => lambda {organization_values},
                           :label => :field_updated_by_organization
    end

    def sql_for_author_organization_field(field, operator, value)

      if value.delete('mine')
        value.push User.current&.organization&.id&.to_s
      end

      case operator
      when "*", "!*" # All / None
        sql_not = operator == "!*" ? 'NOT' : ''
        "(#{Issue.table_name}.author_id #{sql_not} IN (SELECT DISTINCT #{User.table_name}.id FROM #{User.table_name}" +
          " WHERE #{User.table_name}.organization_id IS NOT NULL))"
      when "=", "!"
        cond = value.any? ?
                          "#{User.table_name}.organization_id IN (" + value.collect{|val| "'#{self.class.connection.quote_string(val)}'"}.join(",") + ")" :
                          "1=0"
        sql_not = operator == "!" ? 'NOT' : ''
        "(#{Issue.table_name}.author_id #{sql_not} IN (SELECT DISTINCT #{User.table_name}.id FROM #{User.table_name} WHERE #{cond}))"
      end
    end

    def sql_for_updated_by_organization_field(field, operator, value)
      if value.delete('mine')
        value.push User.current&.organization&.id&.to_s
      end
      cond = value.any? ?
            "#{User.table_name}.organization_id IN (" + value.collect{|val| "'#{self.class.connection.quote_string(val)}'"}.join(",") + ")" :
            "1=0"

      neg = (operator == '!' ? 'NOT' : '')

      subquery = "SELECT 1 FROM #{Journal.table_name}" +
      " WHERE #{Journal.table_name}.journalized_type='Issue' AND #{Journal.table_name}.journalized_id=#{Issue.table_name}.id" +
      " AND (journals.user_id IN (SELECT DISTINCT #{User.table_name}.id FROM #{User.table_name} WHERE #{cond}))" +
      " AND (#{Journal.visible_notes_condition(User.current, :skip_pre_condition => true)})"

      "#{neg} EXISTS (#{subquery})"
    end

    def organization_values
      organization_values = []
      if User.current.logged?
        organization_values << ["<< #{l(:label_my_organization).downcase} >>", "mine"] if User.current.organization.present?
      end
      organization_values += all_organizations_values
      organization_values
    end

    def all_organizations_values
      return @all_organizations_values if @all_organizations_values
      values = []
      Organization.sorted.each do |organization|
        values << [organization.fullname, organization.id.to_s]
      end
      @all_organizations_values = values
    end

  end

end

IssueQuery.prepend PluginOrganizations::IssueQueryPatch

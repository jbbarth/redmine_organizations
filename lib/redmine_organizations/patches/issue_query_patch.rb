require_dependency 'issue_query'

class IssueQuery < Query
  self.available_columns << QueryColumn.new(:author_organization, :groupable => false) if self.available_columns.select { |c| c.name == :author_organization }.empty?
end

module PluginOrganizations

  module IssueQueryPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method :issues_without_author_organization, :issues
        alias_method :issues, :issues_with_author_organization
      end
    end

    module InstanceMethods

      # Returns the issues
      # Valid options are :order, :offset, :limit, :include, :conditions
      def issues_with_author_organization(options={})
        issues = issues_without_author_organization(options)
        if has_column?(:author_organization)
         Issue.load_author_organization(issues)
        end
        issues
      end

    end

  end

end

IssueQuery.prepend PluginOrganizations::IssueQueryPatch

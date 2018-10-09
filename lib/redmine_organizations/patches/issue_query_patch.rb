# frozen_string_literal: true

require_dependency 'issue_query'

class IssueQuery < Query

  self.available_columns << QueryColumn.new(:author_organization, :sortable => false, :groupable => false) if self.available_columns.select { |c| c.name == :author_organization }.empty?

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

  end

end

IssueQuery.prepend PluginOrganizations::IssueQueryPatch

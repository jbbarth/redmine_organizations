# frozen_string_literal: true

require_dependency 'issue_query'

class IssueQuery < Query

  self.available_columns << QueryColumn.new(:author_organization, :sortable => false, :groupable => true) if self.available_columns.select { |c| c.name == :author_organization }.empty?

end

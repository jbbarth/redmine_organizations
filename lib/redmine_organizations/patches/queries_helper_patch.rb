require_dependency 'queries_helper'

module PluginOrganizations
  module QueriesHelperPatch

    def csv_content(column, issue)
      if column.name == :author_organization
        issue.author.organization.to_s
      else
        super
      end
    end

    def column_content(column, issue)
      if column.name == :author_organization
        organization = issue.author.organization
        if organization
          link_to_organization organization
        else
          ""
        end
      else
        super
      end
    end

  end
end

QueriesHelper.prepend PluginOrganizations::QueriesHelperPatch
ActionView::Base.prepend QueriesHelper
IssuesController.prepend QueriesHelper

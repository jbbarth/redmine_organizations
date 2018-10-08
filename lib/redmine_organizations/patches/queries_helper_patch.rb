require_dependency 'queries_helper'

module PluginOrganizations
  module QueriesHelperPatch
    
  end
end

QueriesHelper.prepend PluginOrganizations::QueriesHelperPatch
ActionView::Base.prepend QueriesHelper
IssuesController.prepend QueriesHelper

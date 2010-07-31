module RedmineOrganizations
  module Hooks
    class StylesheetHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context)
        stylesheet_link_tag "organizations", :plugin => :redmine_organizations
      end
    end
  end
end

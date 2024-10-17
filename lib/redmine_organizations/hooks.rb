module RedmineOrganizations
  module Hooks
    class StylesheetHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context)
        stylesheet_link_tag("organizations", :plugin => :redmine_organizations) +
          javascript_include_tag("organizations", :plugin => :redmine_organizations)
      end
    end
  end

  class ModelHooks < Redmine::Hook::Listener
    def after_plugins_loaded(_context = {})
      require_relative 'patches/user_patch'
      require_relative 'patches/role_patch'
      require_relative 'patches/group_patch'
      require_relative 'patches/issue_patch'
      require_relative 'patches/issue_query_patch'
      require_relative 'patches/issues_controller_patch'
      require_relative 'patches/mailer_patch'
      require_relative 'patches/project_patch'
      require_relative 'patches/users_helper_patch'
      require_relative 'patches/member_role_patch'
      require_relative 'patches/member_patch'
      require_relative 'patches/members_helper_patch'
      require_relative 'patches/users_controller_patch'
      require_relative 'patches/application_controller_patch'
      require_relative 'patches/field_format_patch'

      #ensure our helper is included
      ActionView::Base.send(:include, OrganizationsHelper)
    end
  end

end

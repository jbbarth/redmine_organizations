require 'redmine'

# Patches to existing classes/modules
ActiveSupport::Reloader.to_prepare do
  #patches
  require_dependency 'redmine_organizations/patches/user_patch'
  require_dependency 'redmine_organizations/patches/group_patch'
  require_dependency 'redmine_organizations/patches/issue_patch'
  require_dependency 'redmine_organizations/patches/issue_query_patch'
  require_dependency 'redmine_organizations/patches/queries_helper_patch'
  require_dependency 'redmine_organizations/patches/mailer_patch'
  require_dependency 'redmine_organizations/patches/project_patch'
  require_dependency 'redmine_organizations/patches/users_helper_patch'
  require_dependency 'redmine_organizations/patches/member_role_patch'
  require_dependency 'redmine_organizations/patches/member_patch'
  require_dependency 'redmine_organizations/patches/users_controller_patch'
  require_dependency 'redmine_organizations/patches/application_controller_patch'
  #ensure our helper is included
  ActionView::Base.send(:include, OrganizationsHelper)
end

#hooks
require 'redmine_organizations/hooks/view_layouts_base_html_head_hook'

#ensure organizations helper is loaded

Redmine::Plugin.register :redmine_organizations do
  name 'Redmine Organizations plugin'
  author 'Jean-Baptiste BARTH'
  description 'Adds "organization" structure to replace Redmine groups'
  url 'http://github.com/jbbarth/redmine_organizations'
  author_url 'mailto:jeanbaptiste.barth@gmail.com'
  version '3.4.4'
  requires_redmine :version_or_higher => '3.0.0'
  requires_redmine_plugin :redmine_base_rspec, :version_or_higher => '0.0.3' if Rails.env.test?
  requires_redmine_plugin :redmine_base_deface, :version_or_higher => '0.0.1'
  settings :default => {
    'hide_groups_admin_menu' => "0",
  }, :partial => 'settings/organizations_settings'
end

Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :organizations, {:controller => 'organizations'},
            :after => :groups,
            :caption => :label_organization_plural,
            :html => {:class => 'icon'}
end

require 'redmine'

config.to_prepare do
  #patches
  require_dependency 'redmine_organizations/patches/user_patch'
  require_dependency 'redmine_organizations/patches/project_patch'
  require_dependency 'redmine_organizations/patches/users_helper_patch'
  require_dependency 'redmine_organizations/patches/member_role_patch'
  #ensure our helper is included
  ActionView::Base.send(:include, OrganizationsHelper)
end

#hooks
require 'redmine_organizations/hooks/view_layouts_base_html_head_hook'

#additions
require 'awesome_nested_set2/init'

#ensure organizations helper is loaded

Redmine::Plugin.register :redmine_organizations do
  name 'Redmine organizations plugin'
  author 'Jean-Baptiste BARTH'
  description 'Adds organizations objects to Redmine'
  url 'http://github.com/jbbarth/redmine_organizations'
  author_url 'mailto:jeanbaptiste.barth@gmail.com'
  version '0.1'
  requires_redmine :version_or_higher => '1.0.0'
  settings :default => {
    'hide_groups_admin_menu' => "0",
  }, :partial => 'settings/organizations_settings'
end

Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :organizations, {:controller => 'organizations'}, :after => :groups
end

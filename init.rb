require 'redmine'

# Little hack for deface in redmine:
# - redmine plugins are not railties nor engines, so deface overrides are not detected automatically
# - deface doesn't support direct loading anymore ; it unloads everything at boot so that reload in dev works
# - hack consists in adding "app/overrides" path of the plugin in Redmine's main #paths
Rails.application.paths["app/overrides"] ||= []
Rails.application.paths["app/overrides"] << File.expand_path("../app/overrides", __FILE__)

# Patches to existing classes/modules
ActionDispatch::Callbacks.to_prepare do
  #patches
  require_dependency 'redmine_organizations/patches/user_patch'
  require_dependency 'redmine_organizations/patches/group_patch'
  require_dependency 'redmine_organizations/patches/project_patch'
  require_dependency 'redmine_organizations/patches/users_helper_patch'
  require_dependency 'redmine_organizations/patches/member_role_patch'
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
  version '0.2'
  requires_redmine :version_or_higher => '2.0.0'
  settings :default => {
    'hide_groups_admin_menu' => "0",
  }, :partial => 'settings/organizations_settings'
end

Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :organizations, {:controller => 'organizations'}, :after => :groups, :caption => :label_organization_plural
end

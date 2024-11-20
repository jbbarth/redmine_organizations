require 'redmine'

#hooks
require_relative 'lib/redmine_organizations/hooks'

Redmine::Plugin.register :redmine_organizations do
  name 'Redmine Organizations plugin'
  author 'Jean-Baptiste BARTH'
  description 'Adds "organization" structure to replace Redmine groups'
  url 'http://github.com/jbbarth/redmine_organizations'
  version '3.4.4'
  requires_redmine :version_or_higher => '3.0.0'
  requires_redmine_plugin :redmine_base_rspec, :version_or_higher => '0.0.3' if Rails.env.test?
  requires_redmine_plugin :redmine_base_deface, :version_or_higher => '0.0.1'
  settings :default => {
    'hide_groups_admin_menu' => "0",
    'default_team_leader_role' => nil
  }, :partial => 'settings/organizations_settings'
  project_module :issue_tracking do
    permission :share_issues_with_organizations, {}, :require => :member
  end
end

Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :organizations, {:controller => 'organizations'},
            :after => :groups,
            :caption => :label_organization_plural,
            :html => {:class => 'icon'}
end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push :organizations, {:controller => 'organizations'}, :caption => :label_organization_plural,
            :if => Proc.new {User.current.logged?}, :last => true
end

# Support for Redmine 5
if Redmine::VERSION::MAJOR < 6
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end

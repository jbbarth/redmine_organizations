require_dependency 'users_helper'

module UsersHelper
  def user_settings_tabs
    tabs = [{:name => 'general', :partial => 'users/general', :label => :label_general},
            {:name => 'organizations', :partial => 'users/organizations', :label => :label_organization_plural},
            {:name => 'memberships', :partial => 'users/memberships', :label => :label_project_plural}
            ]
    if Group.all.any? && Setting["plugin_redmine_organizations"]["hide_groups_admin_menu"] != "1"
      tabs.insert 1, {:name => 'groups', :partial => 'users/groups', :label => :label_group_plural}
    end
    tabs
  end
end

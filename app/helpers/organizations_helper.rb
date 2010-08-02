module OrganizationsHelper
  def organization_settings_tabs
    tabs = [{:name => 'general', :partial => 'organizations/general', :label => :label_general},
            {:name => 'users', :partial => 'organizations/users', :label => :label_user_plural},
            #{:name => 'memberships', :partial => 'organizations/memberships', :label => :label_project_plural}
            ]
  end
end

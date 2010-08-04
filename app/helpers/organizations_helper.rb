module OrganizationsHelper
  def options_for_membership_project_select(user, projects)
    options = content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---")
    options << project_tree_options_for_select(projects) do |p|
      {:disabled => (user.projects.include?(p))}
    end
    options
  end
  
  def organization_settings_tabs
    tabs = [{:name => 'general', :partial => 'organizations/general', :label => :label_general},
            {:name => 'users', :partial => 'organizations/users', :label => :label_user_plural},
            {:name => 'memberships', :partial => 'organizations/memberships', :label => :label_project_plural}
            ]
  end
end

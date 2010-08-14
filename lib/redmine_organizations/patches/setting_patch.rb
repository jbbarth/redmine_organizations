require_dependency 'setting'

Redmine::MenuManager.map :admin_menu do |menu|
  menu.delete :groups if Setting["plugin_redmine_organizations"]["hide_groups_admin_menu"] == "1"
end

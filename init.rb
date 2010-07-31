require 'redmine'

require 'redmine_organizations/hooks/view_layouts_base_html_head_hook'

Redmine::Plugin.register :redmine_organizations do
  name 'Redmine organizations plugin'
  author 'Jean-Baptiste BARTH'
  description 'Adds organizations objects to Redmine'
  url 'http://github.com/jbbarth/redmine_organizations'
  author_url 'mailto:jeanbaptiste.barth@gmail.com'
  version '0.1'
  requires_redmine :version_or_higher => '1.0.0'
end

Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :organizations, {:controller => 'organizations'}, :after => :groups
end

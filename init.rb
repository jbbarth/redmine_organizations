require 'redmine'

Redmine::Plugin.register :redmine_organizations do
  name 'Redmine organizations plugin'
  author 'Jean-Baptiste BARTH'
  description 'Adds organizations objects to Redmine'
  url 'http://github.com/jbbarth/redmine_organizations'
  author_url 'mailto:jeanbaptiste.barth@gmail.com'
  version '0.1'
  requires_redmine :version_or_higher => '1.0.0'
end

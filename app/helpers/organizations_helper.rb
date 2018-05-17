module OrganizationsHelper
  def organization_settings_tabs
    tabs = [{:name => 'general', :partial => 'organizations/general', :label => :label_general},
            {:name => 'users', :partial => 'organizations/users', :label => :label_user_plural},
            {:name => 'memberships', :partial => 'organizations/memberships', :label => :label_project_plural}
            ]
  end
  
  def link_to_organization(organization, options = {})
    options = {:link_ancestors => true,
               :fullname => true,
               :title => organization.fullname}.merge(options)

    url = organization_path(organization)
    html = {:title => options[:title] }

    if options[:fullname] && options[:link_ancestors]
      h = ""
      organization.ancestors.order('lft').each do |o|
        h << link_to_organization(o, :fullname => false)
        h << Organization::SEPARATOR
      end
      h << link_to(organization.name, url, html)
      h.html_safe
    elsif options[:fullname]
      link_to(organization.fullname, url, html)
    else
      link_to(organization.name, url, html)
    end
  end
  
  def link_to_organization_membership(project, roles=nil, options={})
    html = link_to_project(project)
    html << " (#{roles.sort.map(&:to_s).join(', ')})" if roles.any?
  end
end

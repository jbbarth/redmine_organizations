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

    url = {:controller=>'organizations',:action=>'show',:id=>organization}
    html = {:title => options[:title] }

    if options[:fullname] && options[:link_ancestors]
      h = ""
      organization.ancestors.all(:order => 'lft').each do |o|
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

  # Returns a string for users/groups option tags
  def principals_options_for_select_with_organizations_data(collection, selected=nil)
    s = ''
    if collection.include?(User.current)
      s << content_tag('option', "<< #{l(:label_me)} >>", {:value => User.current.id, 'data-organization'=>User.current.organization_id})
    end
    groups = ''
    collection.sort.each do |element|
      selected_attribute = ' selected="selected"' if option_value_selected?(element, selected) || element.id.to_s == selected
      disabled_attribute = ' disabled="disabled"' if selected.present? && element.try(:organization_id) != selected.try(:organization_id)
      (element.is_a?(Group) ? groups : s) << %(<option value="#{element.id}"#{selected_attribute}#{disabled_attribute} data-organization="#{element.try(:organization_id)}">#{h element.name}</option>)
    end
    unless groups.empty?
      s << %(<optgroup label="#{h(l(:label_group_plural))}">#{groups}</optgroup>)
    end
    s.html_safe
  end
end

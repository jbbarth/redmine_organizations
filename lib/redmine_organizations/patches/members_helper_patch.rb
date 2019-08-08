require_dependency 'members_helper'

module MembersHelper
  def render_principals_for_new_members(project, limit=100, organization=nil)
    scope = Principal.active.visible.sorted.not_member_of(project).like(params[:q])
    if organization
      scope = scope.where(organization_id: organization.self_and_descendants.map(&:id))
    end
    principal_count = scope.count
    principal_pages = Redmine::Pagination::Paginator.new principal_count, limit, params['page']
    principals = scope.offset(principal_pages.offset).limit(principal_pages.per_page).to_a

    s = content_tag('div',
                    content_tag('div', principals_check_box_tags('membership[user_ids][]', principals), :id => 'principals'),
                    :class => 'objects-selection'
    )

    links = pagination_links_full(principal_pages, principal_count, :per_page_links => false) {|text, parameters, options|
      link_to text, autocomplete_project_memberships_path(project, parameters.merge(:q => params[:q], :format => 'js')), :remote => true
    }

    s + content_tag('span', links, :class => 'pagination')
  end
end

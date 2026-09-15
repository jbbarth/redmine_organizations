require_dependency 'members_helper'

module RedmineOrganizations::Patches::MembersHelperPatch
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

  # Paginates members one by one, then groups the page by organization:
  # an organization whose members span several pages is listed on each of them
  def paginate_members_per_organization(project)
    members = project.memberships.preload(:project).includes(:user => [:organization]).sorted
    members = members.active unless Rails.env.test?
    members = members.reject(&:new_record?)

    ordered_members = group_members_by_organization(members).sort_by { |organization, _| organization.try(:fullname).to_s }.flat_map(&:last)
    member_count = ordered_members.size
    member_pages = Redmine::Pagination::Paginator.new(member_count, members_per_page, params['members_page'], 'members_page')
    page_members = ordered_members[member_pages.offset, member_pages.per_page] || []

    [group_members_by_organization(page_members).to_a, member_pages, member_count]
  end

  private

  # The plugin setting only changes the default: a per page value chosen on
  # this list is kept for this list, without affecting the other lists
  def members_per_page
    default_per_page = Setting["plugin_redmine_organizations"]["members_per_page"].to_i
    return controller.per_page_option unless default_per_page > 0

    if Setting.per_page_options_array.include?(params[:per_page].to_i)
      session[:members_per_page] = params[:per_page].to_i
    end
    session[:members_per_page] || default_per_page
  end

  def group_members_by_organization(members)
    # group members have no organization; bucket them under nil
    members.group_by { |member| member.principal.respond_to?(:organization) ? member.principal.organization : nil }
  end
end

MembersHelper.prepend RedmineOrganizations::Patches::MembersHelperPatch
ActionView::Base.prepend MembersHelper

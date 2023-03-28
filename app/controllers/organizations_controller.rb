class OrganizationsController < ApplicationController

  before_action :find_organization_by_id, only: [:show, :edit, :update, :destroy, :add_users, :remove_user, :autocomplete_for_user]
  before_action :require_admin_or_manager, :except => [:index, :show, :autocomplete_users, :fetch_users_by_orga]
  before_action :require_login, :only => [:index, :show, :autocomplete_users]
  before_action :find_project_by_project_id, :only => [:autocomplete_users]
  after_action :update_fullname_and_identifier_of_children, only: [:update]

  layout 'admin'

  def index
    @organizations = Organization.order('lft').includes(:managers, :team_leaders)
    @managers_by_organization = @organizations.map { |o| [o.id, o.managers.map(&:name)] }.to_h
    @team_leaders_by_organization = @organizations.map { |o| [o.id, o.team_leaders.map(&:name)] }.to_h
    @managed_organizations = Organization.managed_by(user: User.current)
    render :layout => (User.current.admin? ? 'admin' : 'base')
  end

  def show
    @projects = @organization.projects.active

    @projects_not_active = @organization.projects.where(:status => [Project::STATUS_CLOSED, Project::STATUS_ARCHIVED])

    @memberships = @organization.memberships.includes(:project).where(Project.visible_condition(User.current, { :skip_pre_condition => true }))

    @subprojects_by_organization = {}
    @subusers = {}

    @users = @organization.users.active.sorted

    @organization.descendants.order("lft").each do |organization|
      @subprojects_by_organization[organization] = organization.projects.active
      @subusers[organization] = organization.users.active.sorted
    end

    @subusers_count = (@organization.users.active | @subusers.values.flatten.uniq).count

    #issues for projects of this organization + sub organizations
    organization_ids = @organization.self_and_descendants_ids
    project_ids = Member.joins(:user).where('users.status = ? AND users.organization_id IN (?)', User::STATUS_ACTIVE, organization_ids).map(&:project_id).uniq
    @issues = Issue.open.visible.on_active_project.where(project_id: project_ids).joins(:priority).order("enumerations.position desc").limit(50)

    render :layout => 'base'

  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def new
    @organization = Organization.new
    @managed_organizations = Organization.managed_by(user: User.current)
    @organization.parent = Organization.find(params[:parent_id]) if params[:parent_id].present?
  end

  def edit
    @roles = Role.find_all_givable
    @projects = Project.active.order('lft')
    @managed_organizations = Organization.managed_by(user: User.current)

    render :layout => (User.current.admin? ? 'admin' : 'base')
  end

  def create
    @organization = Organization.new
    @organization.safe_attributes = params[:organization]
    if @organization.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to(@organization)
    else
      render :action => "new"
    end
  end

  def update
    @organization.safe_attributes = params[:organization]
    if @organization.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to(@organization)
    else
      render :action => "edit"
    end
  end

  def destroy
    @organization.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to(organizations_url)
  end

  def add_users
    @users = User.active.where(id: params[:user_ids])
    @organization.users << @users if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization.identifier, :tab => 'users' }
      format.js
    end
  end

  def remove_user
    @organization.users.delete(User.find(params[:user_id])) if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization.identifier, :tab => 'users' }
      format.js
    end
  end

  def autocomplete_for_user
    @users = User.active.sorted.like(params[:q]).limit(100).to_a - @organization.users
    render :layout => false
  end

  def autocomplete_user_from_id
    @user = User.active.sorted.find_by_id(params[:q])
    render :layout => false
  end

  def autocomplete_users
    @organizations = Organization.where(id: params[:organization_ids])
    @users = @organizations.map { |o| o.users.active }.flatten.compact.uniq.sort_by(&:name)
    render :layout => false
  end

  def fetch_users_by_orga
    @users = User.active.sorted.where("organization_id = ? AND id != ?", params[:orga_id], params[:id])
  end

  def ldap_sync
    return render_error :status => 403 unless Redmine::Plugin.installed?(:redmine_ldap_minequip)

    @organizations = Organization.order('lft').includes(:users)

    ldap_organizations = LdapOrganization.order(:fullpath).pluck(:fullpath)
    intern_organizations = @organizations.map(&:fullpath_from_top_department_in_ldap_organization)
    @unknown_organizations = ldap_organizations - intern_organizations
    @synchronized_organizations = ldap_organizations & intern_organizations

    @synchronizable_organizations = Organization.order('lft').where(top_department_in_ldap: true).map(&:self_and_descendants).flatten.uniq

    render :layout => 'admin'
  end

  def ldap_sync_check_status
    @organization = Organization.find(params[:organization_id])
    sync_members = params[:with_members].present?

    # Fetch LDAP data
    LdapOrganization.reset_ldap_organizations(root: @organization.fullpath_from_top_department_in_ldap_organization, with_people: sync_members)

    # Data to display
    load_data_for_ldap_sync_check_status(@organization)
    load_people_data_for_ldap_sync_check_status(@organization) if sync_members
  end

  def add_organization_from_ldap
    ldap_orga = LdapOrganization.find_by_fullpath(params[:fullpath])
    @organization = Organization.find_or_create_from_ldap(fullpath: ldap_orga.fullpath, description: ldap_orga.cn)
    respond_to do |format|
      format.html { redirect_to ldap_sync_organizations_path(:organization_id => @organization.id) }
      format.js
    end
  end

  def add_all_organizations_from_ldap
    ldap_orgas = LdapOrganization.all
    ldap_orgas.each do |ldap_orga|
      Organization.find_or_create_from_ldap(fullpath: ldap_orga.fullpath,
                                            description: ldap_orga.cn)
    end
    redirect_to ldap_sync_organizations_path
  end

  private

  def load_data_for_ldap_sync_check_status(organization)
    ldap_organizations = LdapOrganization.where("fullpath LIKE ?", "#{organization.fullpath_from_top_department_in_ldap_organization}%").order(:fullpath).pluck(:fullpath)
    intern_organizations = organization.self_and_descendants.map(&:fullpath_from_top_department_in_ldap_organization)
    @unknown_organizations = ldap_organizations - intern_organizations
    @synchronized_organizations = ldap_organizations & intern_organizations
    @desynchronized_organizations = intern_organizations - ldap_organizations
    @combined_organizations = (intern_organizations + @unknown_organizations).sort
  end

  def load_people_data_for_ldap_sync_check_status(organization)
    @ldap_people = LdapPerson.where("organization_fullpath LIKE ?", "#{organization.fullpath_from_top_department_in_ldap_organization}%").order(:organization_fullpath, :sn, :givenname)
    # intern_people = organization.self_and_descendants.map(&:name_with_parents)
    # @unknown_people = @ldap_people - intern_people
    # @synchronized_people = @ldap_people & intern_people
    # @desynchronized_people = intern_people - @ldap_people
    # @combined_people = (intern_people + @unknown_people).sort
  end

  def update_fullname_and_identifier_of_children
    if @organization.previous_changes.include?(:name)
      @organization.children.each do |child|
        child.update_name_with_parents
        child.save
      end
    end
  end
end

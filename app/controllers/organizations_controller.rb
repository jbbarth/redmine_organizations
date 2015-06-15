class OrganizationsController < ApplicationController
  unloadable

  before_filter :require_admin, :only => [:new, :edit, :create, :update, :destroy, :add_users, :remove_user, :autocomplete_for_user, :autocomplete_user_from_id ]
  before_filter :require_login, :only => [:index, :show]
  before_filter :find_project_by_project_id, :can_manage_members, :only => [:create_membership_in_project, :update_roles, :update_user_roles, :destroy_membership_in_project]
  
  layout 'admin'
  
  def index
    @organizations = Organization.all(:order => 'lft')
    render :layout => (User.current.admin? ? 'admin' : 'base')
  end
  
  def show
    @organization = Organization.find(params[:id])

    @projects = @organization.projects

    @memberships = @organization.memberships.includes(:project).where(Project.visible_condition(User.current))

    @subprojects_by_organization = {}
    @subusers = {}

    @users = @organization.users.active
    
    @organization.descendants.order("lft").each do |organization|
      @subprojects_by_organization[organization] = organization.projects
      @subusers[organization] = organization.users.active
    end

    @subusers_count = (@organization.users | @subusers.values.flatten.uniq).count
    
    events = []
    #@users.each do |user|
    #  events << Redmine::Activity::Fetcher.new(User.current, :author => user).events(nil, nil, :limit => 10)
    #end
    #@events_by_day = events.group_by(&:event_date) <<undefined method 'event_date' for Array
    @events_by_day = []

    #issues for projects of this organization + sub organizations
    organization_ids = @organization.self_and_descendants.map(&:id)
    project_ids = Member.joins(:user).where('users.organization_id IN (?)', organization_ids).map(&:project_id).uniq
    opts = {:joins => :priority, :order => "enumerations.position desc", :limit => 50}
    @issues = Issue.open.visible.on_active_project.find_all_by_project_id(project_ids, opts)
    
    render :layout => 'base'

  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def new
    @organization = Organization.new
  end
  
  def edit
    @organization = Organization.find(params[:id])
    @roles = Role.find_all_givable
    @projects = Project.active.all(:order => 'lft')
  end
  
  def create
    @organization = Organization.new(params[:organization])
    if @organization.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to(@organization)
    else
     render :action => "new"
    end
  end
  
  def update
    @organization = Organization.find(params[:id])
    if @organization.update_attributes(params[:organization])
      flash[:notice] = l(:notice_successful_update)
      redirect_to(@organization)
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @organization = Organization.find(params[:id])
    @organization.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to(organizations_url)
  end
  
  def add_users
    @organization = Organization.find(params[:id])
    @users = User.active.find_all_by_id(params[:user_ids])
    @organization.users << @users if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization, :tab => 'users' }
      format.js
    end
  end
  
  def remove_user
    @organization = Organization.find(params[:id])
    @organization.users.delete(User.find(params[:user_id])) if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization, :tab => 'users' }
      format.js
    end
  end
  
  def autocomplete_for_user
    @organization = Organization.find(params[:id])
    @users = User.active.like(params[:q]).find(:all, :limit => 100) - @organization.users
    render :layout => false
  end
  
  def autocomplete_user_from_id
    @user = User.active.find_by_id(params[:q])
    render :layout => false
  end


  def create_membership_in_project
    @organization = Organization.find(params['membership']['organization_id']) if params['membership']['organization_id'].present?
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => @project.id, :tab => 'members' }
      format.js
    end
  end

  def update_roles
    new_members = User.find(params[:membership][:user_ids].reject(&:empty?))
    new_roles = Role.find(params[:membership][:role_ids].reject(&:empty?))
    @organization = Organization.find(params[:organization_id])
    old_organization_roles = @organization.default_roles_by_project(@project)

    @organization.delete_all_organization_roles(@project)
    organization_roles = new_roles.map{ |role| OrganizationRole.new(role_id: role.id, project_id: @project.id) }
    organization_roles.each do |r|
      @organization.organization_roles << r
    end

    @organization.update_project_members(params[:project_id], new_members, new_roles, old_organization_roles)
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => @project.id, :tab => 'members' }
      format.js
    end
  end

  def update_user_roles
    new_roles = Role.find(params[:membership][:role_ids].reject(&:empty?))
    if params[:member_id]
      @member = Member.find(params[:member_id])
      @member.roles = new_roles | @member.principal.organization.default_roles_by_project(@project)
    end
    if params[:group_id] # TODO Modify this hack - create a different action to make it cleaner
      group = GroupBuiltin.find(params[:group_id])
      membership = Member.where(user_id: group.id, project_id: @project.id).first_or_initialize
      if new_roles.present?
        membership.roles = new_roles
        membership.save
      else
        membership.try(:destroy)
      end
    end
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => @project.id, :tab => 'members' }
      format.js
    end
  end

  def destroy_membership_in_project
    @organization = Organization.find(params[:organization_id]) if params[:organization_id]
    @organization.delete_old_project_members(params[:project_id]) if @organization

    @member = Member.find(params[:member_id]) if params[:member_id]
    @member.try(:destroy) if @member

    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => @project.id, :tab => 'members' }
      format.js
    end
  end

  def fetch_users_by_orga
    @users = User.active.sorted.where("organization_id = ? AND id != ?", params[:orga_id], params[:id])
  end

  private
  def can_manage_members
    unless User.current.allowed_to?(:manage_members, @project)
      deny_access
      return
    end
  end

end

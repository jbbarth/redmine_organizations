class OrganizationsController < ApplicationController
  unloadable

  before_filter :require_admin, :except => [:index, :show]
  before_filter :require_login, :only => [:index, :show]
  before_filter :find_project_by_project_id, :can_manage_members, :only => [:create_membership_in_project, :update_roles, :destroy_membership_in_project]
  
  layout 'admin'
  
  def index
    @organizations = Organization.all(:order => 'lft')
    render :layout => (User.current.admin? ? 'admin' : 'base')
  end
  
  def show
    @organization = Organization.find(params[:id])

    @projects = @organization.projects

    @memberships = @organization.memberships.all(:include => :project,
                                                 :conditions => Project.visible_condition(User.current))
    
    @subprojects_by_organization = @organization.descendants.all(:order => "lft").inject({}) do |memo, organization|
      memo[organization] = organization.projects
      memo
    end
    
    @users = @organization.users.active
    @subusers = @organization.descendants.all(:order => "lft").inject({}) do |memo, organization|
      memo[organization] = organization.users.active
      memo
    end
    
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
    @project = Project.find(params['membership']['project_id']) if params['membership']['project_id'].present?
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :project_id => @project, :tab => 'members' }
      format.js
    end
  end

  def update_roles
    new_members = User.find(params[:membership][:user_ids].reject(&:empty?))
    new_roles = Role.find(params[:membership][:role_ids].reject(&:empty?))
    @organization = Organization.find(params[:organization_id])
    @organization.update_project_members(params[:project_id], new_members, new_roles)
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :project_id => params[:project_id], :tab => 'members' }
      format.js
    end
  end

  def destroy_membership_in_project
    @organization = Organization.find(params[:organization_id])
    @organization.delete_old_project_members(params[:project_id])
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => params[:project_id], :tab => 'members' }
      format.js
    end
  end

  private
  def can_manage_members
    unless User.current.allowed_to?(:manage_members, @project)
      deny_access
      return
    end
  end

end

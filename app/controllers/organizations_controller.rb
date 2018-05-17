class OrganizationsController < ApplicationController
  unloadable

  before_filter :require_admin, :only => [:new, :edit, :create, :update, :destroy, :add_users, :remove_user, :autocomplete_for_user, :autocomplete_user_from_id ]
  before_filter :require_login, :only => [:index, :show]
  
  layout 'admin'
  
  def index
    @organizations = Organization.order('lft')
    render :layout => (User.current.admin? ? 'admin' : 'base')
  end
  
  def show
    @organization = Organization.find(params[:id])

    @projects = @organization.projects.active

    @projects_not_active = @organization.projects.where(:status => [Project::STATUS_CLOSED, Project::STATUS_ARCHIVED])

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
    @issues = Issue.open.visible.on_active_project.where(project_id: project_ids).joins(:priority).order("enumerations.position desc").limit(50)
    
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
    @projects = Project.active.order('lft')
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
    @users = User.active.where(id: params[:user_ids])
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
    @users = User.active.like(params[:q]).limit(100).to_a - @organization.users
    render :layout => false
  end
  
  def autocomplete_user_from_id
    @user = User.active.find_by_id(params[:q])
    render :layout => false
  end

  def update_user_roles
    new_roles = Role.find(params[:membership][:role_ids].reject(&:empty?))
    if params[:member_id]
      @member = Member.find(params[:member_id])
      @member.roles = new_roles | @member.principal.organization.default_roles_by_project(@project)
    end
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => @project.id, :tab => 'members' }
      format.js
    end
  end

  def fetch_users_by_orga
    @users = User.active.sorted.where("organization_id = ? AND id != ?", params[:orga_id], params[:id])
  end

end

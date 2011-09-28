class OrganizationsController < ApplicationController
  unloadable

  before_filter :require_admin, :except => :show
  
  layout 'admin'
  
  def index
    @organizations = Organization.all(:order => 'lft')
  end
  
  def show
    @organization = Organization.find(params[:id])
    
    @memberships = @organization.memberships.all(:include => :project,
                                                 :conditions => Project.visible_condition(User.current))
    
    @submemberships = @organization.descendants.all(:order => "lft").inject({}) do |memo, organization|
      memo[organization] = organization.memberships.all(:include => [:project, :organization, :roles],
                                                        :conditions => [ Project.visible_condition(User.current) +
                                                          " AND #{Role.table_name}.hidden_on_overview = ?", false])
      memo
    end
    
    @users = @organization.users
    
    events = []
    #@users.each do |user|
    #  events << Redmine::Activity::Fetcher.new(User.current, :author => user).events(nil, nil, :limit => 10)
    #end
    #@events_by_day = events.group_by(&:event_date) <<undefined method 'event_date' for Array
    @events_by_day = []

    #issues for projects of this organization + sub organizations
    organization_ids = @organization.self_and_descendants.map(&:id)
    project_ids = OrganizationMembership.all(:conditions => {:organization_id => organization_ids}).map(&:project_id)
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
    users = User.find_all_by_id(params[:user_ids])
    @organization.users << users if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization, :tab => 'users' }
      format.js { 
        render(:update) {|page| 
          page.replace_html "tab-content-users", :partial => 'organizations/users'
          users.each {|user| page.visual_effect(:highlight, "user-#{user.id}") }
        }
      }
    end
  end
  
  def remove_user
    @organization = Organization.find(params[:id])
    @organization.users.delete(User.find(params[:user_id])) if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization, :tab => 'users' }
      format.js { render(:update) {|page| page.replace_html "tab-content-users", :partial => 'organizations/users'} }
    end
  end
  
  def copy_user
    user_from = User.find_by_id(params[:copy][:user_from])
    user_to = User.find_by_id(params[:copy][:user_to])
    if user_from && user_to
      user_from.organizations.each do |orga|
        unless orga.users.include?(user_to)
          orga.users << user_to
          orga.save
        end
        orga.memberships.each do |om|
          om.users << user_to unless om.users.include?(user_to)
          om.update_users_memberships
          #om.save
        end
      end
    else
      flash[:error] = l(:label_missing_target_user)
    end
    redirect_to :controller => "users", :action => "edit", :id => user_to, :tab => "organizations"
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
end

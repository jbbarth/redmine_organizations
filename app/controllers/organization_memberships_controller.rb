class OrganizationMembershipsController < ApplicationController
  before_filter :require_login
  before_filter :find_project_by_project_id, :can_manage_members, :only => [:create_in_project, :update_roles, :update_users, :destroy_in_project]
  before_filter :require_admin, :only => [:create, :update, :destroy]

  helper :organizations
  include OrganizationsHelper   
  
  def create
    @membership = OrganizationMembership.new(params[:membership])
    @membership.save
    @organization = @membership.organization
    respond_to do |format|
       format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization, :tab => 'memberships' }
       format.js
     end
  end
  
  def update
    @membership = OrganizationMembership.find(params[:id])
    @membership.update_attributes(params[:membership])
    @organization = @membership.organization
    respond_to do |format|
       format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization, :tab => 'memberships' }
       format.js
     end
  end
  
  def destroy
    membership = OrganizationMembership.find(params[:id]).destroy
    @organization = membership.organization
    respond_to do |format|
      format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization, :tab => 'memberships' }
      format.js
    end
  end
  
  def create_in_project
    @membership = OrganizationMembership.new(params[:membership])
    @membership.save
    @organization = @membership.organization
    @project = @membership.project
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :project_id => @project, :tab => 'members' }
      format.js
    end
  end
  
  def update_roles
    @membership = OrganizationMembership.find(params[:id])
    @membership.update_attributes(params[:membership])
    @organization = @membership.organization
    @project = @membership.project
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :project_id => @project, :tab => 'members' }
      format.js
    end
  end
  
  def update_users
    @organization = Organization.find(params[:organization_id])
    @project = Project.find(params[:project_id])

    new_members = User.find(params[:membership][:user_ids].reject!(&:empty?))
    old_members = User.joins(:members).where("organization_id = ? AND project_id = ?", @organization.id, @project.id).uniq
    OrganizationMembership.delete_old_members(@organization.id, @project.id, old_members)
    roles = Role.joins(:member_roles => {:member => :user}).where("organization_id = ? AND project_id = ?", @organization.id, @project.id).uniq
    new_members.each do |user|
      OrganizationMembership.add_member(user, @project.id, roles)
    end

    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :project_id => @project, :tab => 'members' }
      format.js
    end
  end
  
  def destroy_in_project
    membership = OrganizationMembership.find(params[:id]).destroy
    @organization = membership.organization
    respond_to do |format|
      format.html { redirect_to :controller => 'projects', :action => 'settings', :id => membership.project, :tab => 'members' }
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

class Organizations::MembershipsController < ApplicationController

  helper MembersHelper

  DEFAULT_ROLE_ID = 4 # role_id = 4 => project_member in our case #TODO Make it customizable in settings

  before_action :find_project_by_project_id, :is_allowed_to_manage_members?
  before_action :find_organization, except: [:new, :create_non_members_roles, :update_group_non_member_roles]

  def new
    @member = Member.new
  end

  def edit
    @roles = Role.givable.to_a
    @organization_roles = @organization.default_roles_by_project(@project)
    if Redmine::Plugin.installed?(:redmine_limited_visibility)
      @functions = Function.available_functions_for(@project).sorted
      @functions = Function.active_by_default.sorted if @functions.blank?
      @organization_functions = @organization.default_functions_by_project(@project)
    end
  end

  def update
    if params[:membership]
      roles = Role.where(id: params[:membership][:role_ids].reject(&:empty?))
      users = User.where(id: params[:membership][:user_ids].reject(&:empty?))
    end

    update_members(@organization, users, @project, roles, User.current)

    ActiveRecord::Base.transaction do
      not_manageable_roles = Role.givable.to_a - User.current.managed_roles(@project)
      @organization.delete_all_organization_roles(@project, not_manageable_roles)
      organization_roles = roles.map{ |role| OrganizationRole.new(role_id: role.id, project_id: @project.id) }
      organization_roles.each do |r|
        @organization.organization_roles << r
      end
      give_new_organization_roles_to_all_members(project: @project, organization: @organization)

      if Redmine::Plugin.installed?(:redmine_limited_visibility)
        functions = params[:membership][:function_ids] ? Function.where(id: params[:membership][:function_ids].reject(&:empty?)) : []
        not_manageable_functions = Function.all.to_a - User.current.managed_functions(@project)
        @organization.delete_all_organization_functions(@project, not_manageable_functions)
        organization_functions = functions.map{ |function| OrganizationFunction.new(function_id: function.id, project_id: @project.id) }
        organization_functions.each do |of|
          @organization.organization_functions << of
        end
        give_new_organization_functions_to_all_members(project: @project, organization: @organization)
      end

      saved = @organization.save
    end

    respond_to do |format|
      format.html { redirect_to settings_project_path(@project, :tab => 'members') }
      format.js
      format.api {
        if saved
          render_api_ok
        else
          render_validation_errors(@member)
        end
      }
    end
  end

  def update_members(organization, users, project, roles, current_user)
    current_users = organization.users_by_project(project)
    new_users = users - current_users
    new_users.each do |user|
      member = Member.where(user: user, project: project).first_or_initialize
      member.roles = roles
      member.save!
    end
    # Remove unchecked users (only if deletable)
    to_be_deleted_users = current_users - users
    to_be_deleted_members = Member.where(user: to_be_deleted_users, project: project)
    deletable_members = to_be_deleted_members.select{|m| (m.roles & current_user.managed_roles(project)) == m.roles}
    deletable_members.each do |member|
      member.try(:destroy)
    end
  end

  def create_non_members_roles
    @organization = Organization.find(params['membership']['organization_id'])
    if @organization.present?
      @current_organization_roles = OrganizationRole.where(project_id: @project.id, organization_id: @organization.id)
      if @current_organization_roles.empty?
        @current_organization_roles = [OrganizationRole.create!(project_id: @project.id,
                                                                organization_id: @organization.id,
                                                                non_member_role: true,
                                                                role_id: DEFAULT_ROLE_ID)]
      else
        @current_organization_roles.update_all(non_member_role: true)
      end
    end

    respond_to do |format|
      format.html { redirect_to settings_project_path(@project, :tab => 'members') }
      format.js
    end
  end


  def update_non_members_roles
    new_non_member_roles = params[:membership][:role_ids].reject(&:empty?).map(&:to_i)
    existing_roles = OrganizationRole.where(project_id: @project.id, organization_id: @organization.id).map(&:role_id)
    deleted_roles = existing_roles-new_non_member_roles
    brand_new_roles = new_non_member_roles-existing_roles

    (existing_roles|new_non_member_roles).each do |role_id|
      if deleted_roles.include?(role_id)
        orga_role = OrganizationRole.where(role_id: role_id, project_id: @project.id, organization_id: @organization.id).first
        orga_role.non_member_role = false
        orga_role.save
      else
        if brand_new_roles.include?(role_id)
          OrganizationRole.create(role_id: role_id, project_id: @project.id, organization_id: @organization.id, non_member_role: true)
        else
          orga_role = OrganizationRole.where(role_id: role_id, project_id: @project.id, organization_id: @organization.id).first
          unless orga_role.non_member_role
            orga_role.non_member_role = true
            orga_role.save
          end
        end
      end
    end

    respond_to do |format|
      format.html { redirect_to settings_project_path(@project, :tab => 'members') }
      format.js {render :update}
    end
  end

  def update_group_non_member_roles
    new_roles = Role.find(params[:membership][:role_ids].reject(&:empty?))
    group = GroupBuiltin.find(params[:group_id])
    membership = Member.where(user_id: group.id, project_id: @project.id).first_or_initialize
    if new_roles.present?
      membership.roles = new_roles
      membership.save
    else
      membership.try(:destroy)
    end
    respond_to do |format|
      format.html { redirect_to settings_project_path(@project, :tab => 'members') }
      format.js {render :update}
    end
  end

  def destroy_non_members_roles
    @current_organization_roles = OrganizationRole.where(project_id: @project.id, organization_id: @organization.id)
    @current_organization_roles.update_all(non_member_role: false)
    respond_to do |format|
      format.html { redirect_to settings_project_path(@project, :tab => 'members') }
      format.js
    end
  end

  def destroy_organization
    @organization.users_by_organization_in_project(@project).each do |member|
      if member.deletable?
        member.destroy
      end
    end

    respond_to do |format|
      format.html { redirect_to settings_project_path(@project, :tab => 'members') }
      format.js
    end
  end

  private

  def find_organization
    @organization = Organization.find(params[:id])
  end

  def give_new_organization_roles_to_all_members(project:, organization:)
    organization_roles = @organization.organization_roles.where(project_id: @project.id).map(&:role).reject(&:blank?)
    previous_organization_roles = @organization.default_roles_by_project(@project)
    members = Member.joins(:user).where("project_id = ? AND users.organization_id = ?", project.id, organization.id)
    members.each do |member|
      personal_roles = member.roles - previous_organization_roles
      member.roles = organization_roles | personal_roles
      member.save!
    end
  end

  def is_allowed_to_manage_members?
    unless User.current.allowed_to?(:manage_members, @project)
      deny_access
      return
    end
  end

end

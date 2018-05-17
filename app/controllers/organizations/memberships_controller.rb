class Organizations::MembershipsController < ApplicationController

  before_filter :find_organization
  before_filter :find_project_by_project_id

  def edit
    @roles = Role.givable.to_a
    @organization_roles = @organization.default_roles_by_project(@project)
  end

  def update
    if params[:membership]
      roles = Role.where(id: params[:membership][:role_ids].reject(&:empty?))
    end
    previous_organization_roles = @organization.default_roles_by_project(@project)

    ActiveRecord::Base.transaction do
      @organization.delete_all_organization_roles(@project)
      organization_roles = roles.map{ |role| OrganizationRole.new(role_id: role.id, project_id: @project.id) }
      organization_roles.each do |r|
        @organization.organization_roles << r
      end

      give_new_organization_roles_to_all_members(project: @project,
                                                 organization: @organization,
                                                 organization_roles: organization_roles.map(&:role),
                                                 previous_organization_roles: previous_organization_roles)
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

  private

  def find_organization
    @organization = Organization.find(params[:id])
  end

  def give_new_organization_roles_to_all_members(project:, organization:, organization_roles:, previous_organization_roles:)
    members = Member.joins(:user).where("project_id = ? AND users.organization_id = ?", project.id, organization.id)
    members.each do |member|
      personal_roles = member.roles - previous_organization_roles
      member.roles = organization_roles | personal_roles
      member.save!
    end
  end
end

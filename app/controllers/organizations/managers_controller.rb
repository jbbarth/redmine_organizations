class Organizations::ManagersController < ApplicationController

  before_action :require_admin

  def update
    @organization = Organization.find(params[:id])
    # Managers
    @managers = User.active.where(id: params[:manager_ids])
    OrganizationManager.where(user_id: params[:manager_ids]).delete_all
    @organization.managers = @managers
    # Team leaders
    @team_leaders = User.active.where(id: params[:team_leader_ids])
    OrganizationTeamLeader.where(user_id: params[:team_leader_ids]).delete_all
    @organization.team_leaders = @team_leaders
    @organization.touch
    respond_to do |format|
      format.html { redirect_to edit_organization_path(@organization, :tab => 'users') }
      format.js
    end
  end

end

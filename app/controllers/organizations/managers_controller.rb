class Organizations::ManagersController < ApplicationController

  before_action :find_organization_by_id
  before_action :require_admin_or_manager

  def update
    # Managers
    if User.current.admin? # Managers are not allowed to modify managers
      @managers = User.active.where(id: params[:manager_ids])
      OrganizationManager.where(user_id: params[:manager_ids]).delete_all
      @organization.managers = @managers
    end
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

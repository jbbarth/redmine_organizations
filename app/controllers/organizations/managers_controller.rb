class Organizations::ManagersController < ApplicationController

  before_action :find_organization_by_id
  before_action :require_admin_or_manager

  def update
    # Managers
    if User.current.admin? # Managers are not allowed to modify managers
      managers = User.active.where(id: params[:manager_ids])
      OrganizationManager.where(user_id: params[:manager_ids]).delete_all
      @organization.managers = managers
    end

    # Team leaders
    if params[:team_leader_ids].present?
      team_leaders_ids = params[:team_leader_ids]
      team_leaders = User.active.where(id: team_leaders_ids)
    else
      team_leaders_ids = []
      team_leaders = []
    end
    previous_team_leaders_ids = @organization.team_leaders.map(&:id)

    @organization.team_leaders = team_leaders
    OrganizationTeamLeader.where(user_id: params[:team_leader_ids]).where.not(organization: @organization).delete_all
    @organization.touch

    assign_roles_to_team_leaders(team_leaders_ids, previous_team_leaders_ids)

    respond_to do |format|
      format.html {redirect_to edit_organization_path(@organization, :tab => 'users')}
      format.js
    end

  end

  private

  def assign_roles_to_team_leaders(current_team_leaders_ids, previous_team_leaders_ids)

    projects = @organization.self_and_descendants.map {|org| org.projects}.flatten.uniq.compact.select(&:active?)

    added_team_leaders_ids = current_team_leaders_ids - previous_team_leaders_ids
    removed_team_leaders_ids = previous_team_leaders_ids - current_team_leaders_ids

    added_team_leaders_ids.each do |user_id|
      team_leader = OrganizationTeamLeader.find_by(user_id: user_id, organization_id: @organization.id)
      if team_leader.present?
        team_leader.assign_specific_role(projects: projects)
      end
    end

    removed_team_leaders_ids.each do |user_id|
      OrganizationTeamLeader.remove_specific_role(user_id: user_id, projects: projects)
    end
  end

end

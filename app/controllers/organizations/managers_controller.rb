class Organizations::ManagersController < ApplicationController

  before_action :find_organization_by_id
  before_action :require_admin_or_manager

  def update
    # Managers
    if User.current.admin? # Managers are not allowed to modify managers
      previous_managers_ids = @organization.managers.map(&:id)
      managers = User.where(id: params[:manager_ids])
      managers_ids = managers.map(&:id)
      add_managers_ids = managers_ids - previous_managers_ids
      removed_managers_ids = previous_managers_ids - managers_ids

      OrganizationManager.where(user_id: removed_managers_ids).delete_all
      @organization.managers = managers

      OrganizationManager.send_notification_to_added_managers(User.current, add_managers_ids, @organization) if add_managers_ids.any?
      OrganizationManager.send_notification_to_removed_managers(User.current, removed_managers_ids, @organization) if removed_managers_ids.any?
    end

    # Team leaders
    team_leaders = User.where(id: params[:team_leader_ids])
    team_leaders_ids = team_leaders.map(&:id)
    previous_team_leaders_ids = @organization.team_leaders.map(&:id)
    added_team_leaders_ids = team_leaders_ids - previous_team_leaders_ids
    removed_team_leaders_ids = previous_team_leaders_ids - team_leaders_ids

    OrganizationTeamLeader.where(user_id: params[:team_leader_ids]).where.not(organization: @organization).delete_all
    OrganizationTeamLeader.where(user_id: removed_team_leaders_ids).delete_all
    @organization.team_leaders = team_leaders

    OrganizationTeamLeader.send_notification_to_added_team_leaders(User.current, added_team_leaders_ids, @organization) if added_team_leaders_ids.any?
    OrganizationTeamLeader.send_notification_to_removed_team_leaders(User.current, removed_team_leaders_ids, @organization) if removed_team_leaders_ids.any?

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

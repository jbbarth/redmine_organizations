class Organizations::TeamLeadersController < ApplicationController

  before_action :require_admin_or_manager
  before_action :find_organization_by_id, only: [:update]

  def assign_to_team_projects

    if params[:user_id].present?
      team_leaders = OrganizationTeamLeader.where(user_id: params[:user_id]).includes(:user, :organization)
    else
      if params[:organization_id].present?
        team_leaders = OrganizationTeamLeader.where(organization_id: params[:organization_id]).includes(:user, :organization)
      else
        team_leaders = []
      end
    end

    if team_leaders.empty?
      @message = "Aucun chef d'équipe à affecter"
    else

      if team_leaders.size > 1
        @message = "Modification des rôles des utilisateurs #{team_leaders.map(&:user).join(', ')}.<br>Ils disposent désormais du rôle leur permettant de gérer les membres de leur équipe sur tous les projets concernés."
      else
        @message = "Modification des rôles de l'utilisateur #{team_leaders.map(&:user).join(', ')}.<br>Il dispose désormais du rôle lui permettant de gérer les membres sur tous les projets de son équipe."
      end

      projects = team_leaders.map(&:projects).flatten.uniq
      team_leaders.each do |team_leader|
        response = team_leader.assign_specific_role(projects: projects)
        @message << '<br>' + response.join('<br>')
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def update
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

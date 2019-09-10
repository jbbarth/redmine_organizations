class Organizations::TeamLeadersController < ApplicationController

  before_action :require_admin_or_manager

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

end

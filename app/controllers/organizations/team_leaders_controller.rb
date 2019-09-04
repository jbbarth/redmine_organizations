class Organizations::TeamLeadersController < ApplicationController

  before_action :require_admin_or_manager

  def assign_to_team_projects

    if params[:user_id].present?
      user = User.find(params[:user_id])
      users = [user]
      orga = user.organization
      @message = "Modification des rôles de l'utilisateur #{user}.<br>Il dispose désormais du rôle lui permettant de gérer les membres de son équipe sur tous les projets concernés."
    else
      if params[:organization_id].present?
        orga = Organization.find(params[:organization_id])
        users = orga.team_leaders
        if users.empty?
          @message = "Aucun chef d'équipe à affecter"
        else
          @message = "Modification des rôles des utilisateurs : #{users.join(', ')}.<br>Ils disposent désormais du rôle leur permettant de gérer les membres de leur équipe sur tous les projets concernés."
        end
      else
        users = []
      end
    end

    # puts "** Mise à jour pour l'organisation #{orga} **"

    projects = orga.self_and_descendants.map {|org| org.projects}.flatten.uniq.compact.select(&:active?) if orga.present?
    # puts "Nombre de projets concernés : #{projects.size}"

    # project_member = Role.find(4)
    gestionnaire = Role.find(23)

    users.each do |user|
      projects.each do |p|
        member = user.membership(p)
        if member.blank?
          member = Member.new(user: user, project: p)
          member.roles << gestionnaire
          if member.save
            @message << "<br>#{user} ajouté au projet : #{p}"
          else
            @message << "<br>! #{member.errors.messages} | #{p.identifier}"
          end
        end
        member.roles << gestionnaire
        member.functions << orga.self_and_descendants.map {|org| org.functions_by_project(p)}.flatten.uniq.compact
        member.save
      end
    end

    respond_to do |format|
      format.js
    end
  end

end

class Organizations::TeamLeadersController < ApplicationController

  before_action :require_admin

  def assign_to_team_projects

    if params[:user_id].present?
      user = User.find(params[:user_id])
      users = [user]
      orga = user.organization
    else
      if params[:organization_id].present?
        orga = Organization.find(params[:organization_id])
        users = orga.team_leaders
      else
        users = []
      end
    end

    puts "** Mise à jour pour l'organisation #{orga} **"

    projects = orga.self_and_descendants.map {|org| org.projects}.flatten.uniq.compact.select(&:active?) if orga.present?
    puts "Nombre de projets concernés : #{projects.size}"

    project_member = Role.find(4)
    gestionnaire = Role.find(23)

    @message = "Modification des rôles des utilisateurs : #{users.join(', ')}. Ils disposent désormais des rôles leur permettant de gérer leur équipe sur tous les projets concernés."

    users.each do |user|
      projects.each do |p|
        member = user.membership(p)
        if member.blank?
          member = Member.new(user: user, project: p)
          member.roles << project_member
          if member.save
            @message << "\\n#{user} ajouté au projet : #{p}"
          else
            @message << "\\n! #{member.errors.messages} | #{p.identifier}"
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

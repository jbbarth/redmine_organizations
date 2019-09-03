class Organizations::TeamLeadersController < ApplicationController

  before_action :require_admin

  def assign_to_team_projects

    @user = User.find(params[:user_id])
    orga = @user.organization
    puts "** Mise à jour pour l'organisation #{orga} **"

    projects = orga.self_and_descendants.map {|org| org.projects}.flatten.uniq.compact.select(&:active?)
    puts "Nombre de projets concernés : #{projects.size}"

    project_member = Role.find(4)
    gestionnaire = Role.find(23)

    @message = "#{@user} dispose désormais des rôles lui permettant de gérer son équipe sur tous les projets concernés."

    # users = [@user]
    # users.each do |user|
      user = @user
      projects.each do |p|
        member = user.membership(p)
        if member.blank?
          member = Member.new(user: user, project: p)
          member.roles << project_member
          if member.save
            @message << "\\nAjouté au projet : #{p}"
          else
            @message << "\\n! #{member.errors.messages} | #{p.identifier}"
          end
        end
        member.roles << gestionnaire
        member.functions << orga.self_and_descendants.map {|org| org.functions_by_project(p)}.flatten.uniq.compact
        member.save
      end
    # end

    respond_to do |format|
      format.js
    end
  end

end

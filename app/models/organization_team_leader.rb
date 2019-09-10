class OrganizationTeamLeader < ActiveRecord::Base

  belongs_to :user
  belongs_to :organization

  TEAM_LEADER_ROLE = Role.find(23) #Gestionnaire

  def organization_and_descendants
    self.organization.self_and_descendants
  end

  def projects
    organization_and_descendants.map {|org| org.projects}.flatten.uniq.compact.select(&:active?)
  end

  def assign_specific_role(projects:)
    response = []
    projects.each do |project|
      response << assign_specific_role_per_project(project)
    end
    response.compact
  end

  def assign_specific_role_per_project(project)
    member = self.user.membership(project)
    if member.blank?
      member = Member.new(user: user, project: project)
      response = "#{self.user} ajouté au projet : #{project}"
    end
    member.roles |= Array.wrap(TEAM_LEADER_ROLE)
    member.functions |= self.organization.self_and_descendants.map {|org| org.functions_by_project(project)}.flatten.uniq.compact
    if member.save
      response
    else
      "! #{member.errors.messages} | #{project.identifier}"
    end
  end

  def self.remove_specific_role(user_id:, projects:)
    response = []
    projects.each do |project|
      response << remove_specific_role_per_project(user_id, project)
    end
    response.compact
  end

  def self.remove_specific_role_per_project(user_id, project)
    member = Member.find_by(user_id: user_id, project_id: project.id)
    if member.present?
      member.roles -= Array.wrap(TEAM_LEADER_ROLE)
      if member.roles.empty?
        member.delete
      else
        member.save
      end
    end
  end
end

class OrganizationTeamLeader < ActiveRecord::Base

  belongs_to :user
  belongs_to :organization

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
    if Setting["plugin_redmine_organizations"]["default_team_leader_role"].present?
      member.roles |= Array.wrap(Role.find(Setting["plugin_redmine_organizations"]["default_team_leader_role"]))
    end

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
      if Setting["plugin_redmine_organizations"]["default_team_leader_role"].present?
        member.roles -= Array.wrap(Role.find(Setting["plugin_redmine_organizations"]["default_team_leader_role"]))
      end
      if member.roles.empty?
        member.delete
      else
        member.save
      end
    end
  end

  def self.send_notification_to_added_team_leaders(change_author, new_leader_ids, organization)
    new_leader_ids.each do |user_id|
      new_team_leader = User.find(user_id)
      Mailer.notify_new_organization_team_leader(change_author, new_team_leader, organization)
    end
  end

  def self.send_notification_to_removed_team_leaders(change_author, removed_leader_ids, organization)
    removed_leader_ids.each do |user_id|
      removed_team_leader = User.find(user_id)
      Mailer.notify_deleted_organization_team_leader(change_author, removed_team_leader, organization)
    end
  end
end

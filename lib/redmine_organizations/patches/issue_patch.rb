require_dependency "issue"

class Issue

  has_many :issues_organizations, dependent: :destroy
  has_many :organizations, through: :issues_organizations

  # Preloads author's organization for a collection of issues
  def self.load_author_organization(issues, user = User.current)
    if issues.any?
      issue_ids = issues.map(&:id)
      author_organization_per_issue = Issue.joins(author: :organization).
        select('issues.id as issue_id, organizations.id as organization_id').
        where('issues.id' => issue_ids).map do |issue|
        {
          issue_id: issue.issue_id,
          organization_id: issue.organization_id
        }
      end
      organizations_names = Organization.all.map do |o|
        {
          id: o.id,
          name: o.to_s
        }
      end
      issues.each do |issue|
        organization = author_organization_per_issue.detect { |i| i[:issue_id] == issue.id }
        if organization
          organization_name = organizations_names.detect { |n| n[:id] == organization[:organization_id] }
          issue.instance_variable_set("@author_organization", organization_name ? organization_name[:name] : '')
        else
          issue.instance_variable_set("@author_organization", '')
        end
      end
    end
  end

  def author_organization
    if @author_organization
      @author_organization
    else
      author.organization.to_s
    end
  end

  def related_organizations_members
    organizations.map(&:users).flatten.uniq.compact
  end

  def shared_with?(user = User.current)
    related_organizations_members.include?(user)
  end

  def related_organizations
    organizations.to_a
  end

end

module RedmineOrganizations::Patches::IssuePatch
  def organization_emails
    organization_ids = project.users.active.pluck(:organization_id)
    # here we use #where instead of #find because #find will throw an
    # exception if one of the organizations doesn't exist, and I'm not
    # sure that we manage organizations' deletion correctly enough to
    # be sure it won't ever break
    Organization.joins(:organization_notifications)
                .where('organization_notifications.project_id = ?', project.id)
                .where(id: organization_ids)
                .pluck(:mail)
                .select(&:present?)
  end

  # Returns true if usr or current user is allowed to view the issue
  def visible?(usr = nil)
    visibility = super
    if visibility
      return visibility
    else
      usr ||= User.current
      user_organization = usr.organization
      if self.organizations.include?(user_organization)
        true # Always visible by associated organization members
      else
        visibility
      end
    end
  end

  # Returns the users that should be notified
  def notified_users
    super | notified_as_member_of_related_organizations
  end

  def notified_as_member_of_related_organizations
    related_organizations_members.select { |u| u.active? && u.notify_about?(self) }
  end

  def editable?(user = User.current)
    super || (shared_with?(user) && author.present? ? super(author.present? ? author : user) : false)
  end

  # Returns true if user or current user is allowed to edit the issue
  def attributes_editable?(user = User.current)
    super || (shared_with?(user) && author.present? ? super(author.present? ? author : user) : false)
  end

  def attachments_addable?(user = User.current)
    super || (shared_with?(user) && author.present? ? super(author.present? ? author : user) : false)
  end

  # Overrides Redmine::Acts::Attachable::InstanceMethods#attachments_editable?
  def attachments_editable?(user = User.current)
    super || (shared_with?(user) && author.present? ? super(author) : false)
  end

  # Returns true if user or current user is allowed to add notes to the issue
  def notes_addable?(user = User.current)
    super || (shared_with?(user) && author.present? ? super(author) : false)
  end

  def visible_custom_field_values(user = nil)
    if shared_with?(user)
      super | super(author)
    else
      super
    end
  end

  def safe_attributes=(attrs, user = User.current)
    if shared_with?(user)
      super | super(attrs, author)
    else
      super
    end
  end

  def workflow_rule_by_attribute(user = nil)
    if shared_with?(user)
      super(author)
    else
      super
    end
  end

  def visible_journals_with_index(user = User.current)
    if shared_with?(user)
      super(author)
    else
      super
    end
  end

  def new_statuses_allowed_to(user = User.current, include_default = false)
    if shared_with?(user)
      super | super(author, include_default)
    else
      super
    end
  end

  def css_classes(user = User.current)
    if shared_with?(user)
      super(author)
    else
      super
    end
  end

  def allowed_target_projects_for_subtask(user = User.current)
    if shared_with?(user)
      super(author)
    else
      super
    end
  end

  def allowed_target_projects(user = User.current, scope = nil)
    if shared_with?(user)
      super(author, scope)
    else
      super
    end
  end

  def allowed_target_trackers(user = User.current)
    if shared_with?(user)
      super(author)
    else
      super
    end
  end

  module ClassMethods
    def visible_condition(user, options = {})
      if user.organization_id.present?
        organizations_issues_statement = Issue.joins(:issues_organizations)
                                              .where("issues_organizations.organization_id = ?", user.organization_id)
                                              .select(:id)
                                              .to_sql
        statement_through_related_organization = "#{Issue.table_name}.id IN (#{organizations_issues_statement})"

        "(#{super} OR #{statement_through_related_organization})"
      else
        super
      end
    end
  end

  def self.prepended(base)
    class << base
      prepend ClassMethods
    end
  end

end
Issue.prepend RedmineOrganizations::Patches::IssuePatch

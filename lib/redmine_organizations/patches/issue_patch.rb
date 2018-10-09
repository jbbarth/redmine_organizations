require_dependency "issue"

class Issue < ActiveRecord::Base

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
        organization = author_organization_per_issue.detect {|i| i[:issue_id] == issue.id}
        if organization
          organization_name = organizations_names.detect {|n| n[:id] == organization[:organization_id]}
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

end


module IssuePatchWithOrganizations
  def organization_emails
    return [] unless project.notify_organizations
    organization_ids = project.users.active.pluck(:organization_id)
    # here we use #where instead of #find because #find will throw an
    # exception if one of the organizations doesn't exist, and I'm not
    # sure that we manage organizations' deletion correctly enough to
    # be sure it won't ever break
    Organization.where(id: organization_ids, notified: true)
        .pluck(:mail)
        .select(&:present?)
  end
end
Issue.prepend IssuePatchWithOrganizations

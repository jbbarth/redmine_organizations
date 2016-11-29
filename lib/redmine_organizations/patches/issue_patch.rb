require_dependency "issue"

module IssuePatchWithOrganizations
  def organization_emails
    organization_ids = project.users.active.pluck(:organization_id)
    # here we use #where instead of #find because #find will throw an
    # exception if one of the organizations doesn't exist, and I'm not
    # sure that we manage organizations' deletion correctly enough to
    # be sure it won't ever break
    Organization.where(:id => organization_ids)
                .pluck(:mail)
                .select(&:present?)
  end
end
Issue.prepend IssuePatchWithOrganizations

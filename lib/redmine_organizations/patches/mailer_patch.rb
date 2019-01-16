require_dependency 'mailer'

module MailerPatchWithOrganizations

  # Monkey-patch recipients to add organization's addresses
  def mail(headers={}, &block)
    if @issue
      # TODO Modify this function to send a DIFFERENT mail to the organization (since Redmine 4: only one recipient per mail sent)
      # headers = add_organizations_mails(headers, @issue)
    end
    super if defined?(super)
  end

  private
  def add_organizations_mails(headers, issue)
    headers[:cc] ||= []
    headers[:cc].push issue.organization_emails
    headers
  end
end

Mailer.prepend MailerPatchWithOrganizations

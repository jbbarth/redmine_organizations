require_dependency 'mailer'

=begin
module MailerPatchWithOrganizations

  # Monkey-patch recipients to add organization's addresses
  def mail(headers={}, &block)
    if @issue
      headers = add_organizations_mails(headers, @issue)
    end
    super if defined?(super)
  end

  private
  def add_organizations_mails(headers, issue)
    headers[:cc] ||= []
    headers[:cc] << issue.organization_emails
    headers
  end
end

Mailer.prepend MailerPatchWithOrganizations
=end

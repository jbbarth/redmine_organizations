require_dependency 'mailer'

module MailerPatchWithOrganizations

  module ClassMethods
    def notify_new_organization_manager(change_author, new_manager, organization)
      notification_to_new_organization_manager(change_author, new_manager, organization).deliver_later
    end

    def notify_deleted_organization_manager(change_author, manager, organization)
      notification_to_deleted_organization_manager(change_author, manager, organization).deliver_later
    end

    def notify_new_organization_team_leader(change_author, new_manager, organization)
      notification_to_new_organization_team_leader(change_author, new_manager, organization).deliver_later
    end

    def notify_deleted_organization_team_leader(change_author, manager, organization)
      notification_to_deleted_organization_team_leader(change_author, manager, organization).deliver_later
    end
  end

  def self.prepended(mod)
    mod.singleton_class.prepend(ClassMethods)
  end

  def notification_to_new_organization_manager(change_author, new_manager, organization)
    @author = change_author
    @organization = organization
    @user = new_manager
    subject = "[#{Setting.app_title}] #{t('mail_subject_updated_role')}"
    mail :to => new_manager.mail,
         :subject => subject do |format|
      format.text
      format.html unless Setting.plain_text_mail?
    end
  end

  def notification_to_deleted_organization_manager(change_author, manager, organization)
    @author = change_author
    @organization = organization
    @user = manager
    subject = "[#{Setting.app_title}] #{t('mail_subject_updated_role')}"
    mail :to => manager.mail,
         :subject => subject do |format|
      format.text
      format.html unless Setting.plain_text_mail?
    end
  end

  def notification_to_new_organization_team_leader(change_author, user, organization)
    @author = change_author
    @organization = organization
    @user = user
    subject = "[#{Setting.app_title}] #{t('mail_subject_updated_role')}"
    mail :to => user.mail,
         :subject => subject do |format|
      format.text
      format.html unless Setting.plain_text_mail?
    end
  end

  def notification_to_deleted_organization_team_leader(change_author, user, organization)
    @author = change_author
    @organization = organization
    @user = user
    subject = "[#{Setting.app_title}] #{t('mail_subject_updated_role')}"
    mail :to => user.mail,
         :subject => subject do |format|
      format.text
      format.html unless Setting.plain_text_mail?
    end
  end

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

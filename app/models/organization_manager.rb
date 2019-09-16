class OrganizationManager < ActiveRecord::Base

  belongs_to :user
  belongs_to :organization

  def self.send_notification_to_added_managers(change_author, new_managers_ids, organization)
    new_managers_ids.each do |user_id|
      new_manager = User.find(user_id)
      Mailer.notify_new_organization_manager(change_author, new_manager, organization)
    end
  end

  def self.send_notification_to_removed_managers(change_author, removed_managers_ids, organization)
    removed_managers_ids.each do |user_id|
      removed_manager = User.find(user_id)
      Mailer.notify_deleted_organization_manager(change_author, removed_manager, organization)
    end
  end

end

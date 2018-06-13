class RemoveNotifiedFields < ActiveRecord::Migration
  def self.up
    remove_column :organizations, :notified
    remove_column :projects, :notify_organizations
  end

  def self.down
    add_column :organizations, :notified, :boolean
    add_column :projects, :notify_organizations, :boolean, :default => false
  end
end

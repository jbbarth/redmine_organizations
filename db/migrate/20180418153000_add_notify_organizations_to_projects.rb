class AddNotifyOrganizationsToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :notify_organizations, :boolean, :default => false
  end

  def self.down
    remove_column :projects, :notify_organizations
  end
end

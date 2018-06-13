class AddOrganizationNotificationsTable < ActiveRecord::Migration
  def self.up
    create_table :organization_notifications do |t|
      t.column :organization_id, :integer, :null => false
      t.column :project_id, :integer, :null => false
    end
    add_index :organization_notifications, [:organization_id]
    add_index :organization_notifications, [:project_id]
    add_index :organization_notifications, [:organization_id, :project_id], name: "index_organization_notifications_per_project"
  end

  def self.down
    drop_table :organization_notifications
  end
end

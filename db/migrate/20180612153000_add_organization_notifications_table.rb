class AddOrganizationNotificationsTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :organization_notifications do |t|
      t.column :organization_id, :integer, :null => false
      t.column :project_id, :integer, :null => false
    end unless ActiveRecord::Base.connection.table_exists? 'organization_notifications'
    add_index :organization_notifications, [:organization_id] unless ActiveRecord::Base.connection.index_exists?(:organization_notifications, [:organization_id])
    add_index :organization_notifications, [:project_id] unless ActiveRecord::Base.connection.index_exists?(:organization_notifications, [:project_id])
    add_index :organization_notifications, [:organization_id, :project_id], name: "index_organization_notifications_per_project" unless ActiveRecord::Base.connection.index_exists?(:organization_notifications, [:organization_id, :project_id], name: "index_organization_notifications_per_project")
  end

  def self.down
    drop_table :organization_notifications
  end
end

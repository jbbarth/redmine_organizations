class AddOrganizationManagersTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :organization_managers do |t|
      t.column :organization_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
    end unless ActiveRecord::Base.connection.table_exists? 'organization_managers'
    add_index :organization_managers, [:organization_id] unless ActiveRecord::Base.connection.index_exists?(:organization_managers, [:organization_id])
    add_index :organization_managers, [:user_id] unless ActiveRecord::Base.connection.index_exists?(:organization_managers, [:user_id])
  end

  def self.down
    drop_table :organization_managers
  end
end

class CreateOrganizationUsers < ActiveRecord::Migration
  def self.up
    create_table :organization_users do |t|
      t.column :organization_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :function, :integer, :default => 0
      t.column :description, :string
    end
    add_index :organization_users, [:organization_id, :user_id], :unique => true, :name => :organizations_users_ids
  end

  def self.down
    drop_table :organization_users
  end
end

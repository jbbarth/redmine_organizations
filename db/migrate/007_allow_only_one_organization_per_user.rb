class AllowOnlyOneOrganizationPerUser < ActiveRecord::Migration
  def self.up
    add_column :users, :organization_id, :integer
    User.connection.execute("SELECT * FROM organization_users").each do |result|
      user = User.find_by_id(result["user_id"])
      user.update_attribute(:organization_id, result["organization_id"]) if user
    end
    drop_table :organization_users
  end

  def self.down
    remove_column :users, :organization_id
    create_table :organization_users do |t|
      t.column :organization_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :function, :integer, :default => 0
      t.column :description, :string
    end
    add_index :organization_users, [:organization_id, :user_id], :unique => true, :name => :organizations_users_ids
  end
end

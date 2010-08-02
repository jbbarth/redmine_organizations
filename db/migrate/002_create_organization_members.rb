class CreateOrganizationMembers < ActiveRecord::Migration
  def self.up
    create_table :organization_members, :id => false do |t|
      t.column :organization_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
      t.column :function, :integer, :default => 0
      t.column :description, :string
    end
    add_index :organization_members, [:organization_id, :user_id], :unique => true, :name => :organizations_members_ids
  end

  def self.down
    drop_table :organization_members
  end
end

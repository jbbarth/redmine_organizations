class RemoveOrganizationRoles < ActiveRecord::Migration[4.2]
  def self.up
    drop_table :organization_roles
  end

  def self.down
    create_table :organization_roles do |t|
      t.column :organization_membership_id, :integer, :null => false
      t.column :role_id, :integer, :null => false
      t.column :inherited_from, :integer
    end
    add_index :organization_roles, [:organization_membership_id], :name => :index_org_roles_on_org_id
    add_index :organization_roles, [:role_id], :name => :index_org_roles_on_role_id
  end
end

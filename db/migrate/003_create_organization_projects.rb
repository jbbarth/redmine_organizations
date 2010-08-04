class CreateOrganizationProjects < ActiveRecord::Migration
  def self.up
    create_table :organization_memberships do |t|
      t.column :organization_id, :integer, :null => false
      t.column :project_id, :integer, :null => false
    end
    add_index :organization_memberships, [:organization_id], :name => :index_org_memberships_on_org_id
    add_index :organization_memberships, [:project_id], :name => :index_org_memberships_on_project_id
    
    create_table :organization_roles do |t|
      t.column :organization_membership_id, :integer, :null => false
      t.column :role_id, :integer, :null => false
      t.column :inherited_from, :integer
    end
    add_index :organization_roles, [:organization_membership_id], :name => :index_org_roles_on_org_id
    add_index :organization_roles, [:role_id], :name => :index_org_roles_on_role_id
  end

  def self.down
    drop_table :organization_users
    drop_table :organization_roles
  end
end

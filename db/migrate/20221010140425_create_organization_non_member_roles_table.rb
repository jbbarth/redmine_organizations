class CreateOrganizationNonMemberRolesTable < ActiveRecord::Migration[4.2]

  def self.up
    create_table :organization_non_member_roles do |t|
      t.column :organization_id, :integer, :null => false
      t.column :project_id, :integer, :null => false
      t.column :role_id, :integer, :null => false
    end
    add_index :organization_non_member_roles, [:organization_id], :name => :index_org_non_member_roles_on_orga_id
    add_index :organization_non_member_roles, [:project_id], :name => :index_org_non_member_roles_on_project_id
    add_index :organization_non_member_roles, [:role_id], :name => :index_org_non_member_roles_on_role_id
    add_index :organization_non_member_roles, [:role_id, :project_id, :organization_id], unique: true, :name => :unicity_index_org_non_member_roles_on_role_and_project

    # recreate current organizations non member roles
    OrganizationRole.where("organization_roles.non_member_role = ?", true).each do |org_role|
      OrganizationNonMemberRole.create(:project_id => org_role.project_id, :organization_id => org_role.organization_id, :role_id => org_role.role_id)
    end
  end

  def self.down
    drop_table :organization_non_member_roles
  end

end

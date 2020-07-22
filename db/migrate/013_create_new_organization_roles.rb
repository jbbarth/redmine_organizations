class CreateNewOrganizationRoles < ActiveRecord::Migration[4.2]
  def self.up
    create_table :organization_roles do |t|
      t.column :organization_id, :integer, :null => false
      t.column :project_id, :integer, :null => false
      t.column :role_id, :integer, :null => false
    end
    add_index :organization_roles, [:organization_id], :name => :index_org_roles_on_org_id
    add_index :organization_roles, [:project_id], :name => :index_org_roles_on_project_id
    add_index :organization_roles, [:role_id], :name => :index_org_roles_on_role_id
    add_index :organization_roles, [:role_id, :project_id, :organization_id], unique: true, :name => :unicity_index_org_roles_on_role_and_project

    # init current organizations roles
    member_count = Member.count
    Member.all.each_with_index do |member, i|
      puts "#{i}/#{member_count}" if i % 250 == 0
      member.roles.each do |role|
        OrganizationRole.create(:project_id => member.project_id, :organization_id => member.user.organization_id, :role_id => role.id) if member.user
      end
    end
  end

  def self.down
    drop_table :organization_roles
  end
end

class AddNonMemberRoleToOrganizationRoles < ActiveRecord::Migration[4.2]
  def self.up
    add_column :organization_roles, :non_member_role, :boolean, :default => false
  end

  def self.down
    remove_column :organization_roles, :non_member_role
  end
end

class AddAllOrganizationsManagedToRoles < ActiveRecord::Migration[5.2]
  def self.up
    add_column :roles, :all_organizations_managed, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :roles, :all_organizations_managed
  end
end

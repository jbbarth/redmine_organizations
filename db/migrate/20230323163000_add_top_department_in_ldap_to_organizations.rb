class AddTopDepartmentInLdapToOrganizations < ActiveRecord::Migration[4.2]
  def self.up
    add_column :organizations, :top_department_in_ldap, :boolean
  end

  def self.down
    remove_column :organizations, :top_department_in_ldap
  end
end

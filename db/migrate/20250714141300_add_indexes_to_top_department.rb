class AddIndexesToTopDepartment < ActiveRecord::Migration[6.1]
  def change
    add_index :organizations, :lft unless index_exists?(:organizations, :lft)
    add_index :organizations, :rgt unless index_exists?(:organizations, :rgt)
    add_index :organizations, :top_department_in_ldap unless index_exists?(:organizations, :top_department_in_ldap)
  end
end

class AddFullnameToOrganizations < ActiveRecord::Migration[4.2]
  def self.up
    add_column :organizations, :fullname, :string
  end

  def self.down
    remove_column :organizations, :fullname
  end
end

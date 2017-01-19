class AddFullnameToOrganizations < ActiveRecord::Migration
  def self.up
    add_column :organizations, :fullname, :string
  end

  def self.down
    remove_column :organizations, :fullname
  end
end

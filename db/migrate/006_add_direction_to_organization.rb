class AddDirectionToOrganization < ActiveRecord::Migration
  def self.up
    add_column :organizations, :direction, :boolean
  end

  def self.down
    remove_column :organizations, :direction
  end
end

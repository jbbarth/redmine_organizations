class AddDirectionToOrganization < ActiveRecord::Migration[4.2]
  def self.up
    add_column :organizations, :direction, :boolean
  end

  def self.down
    remove_column :organizations, :direction
  end
end

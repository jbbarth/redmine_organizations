class AddIdentifierToOrganizations < ActiveRecord::Migration[4.2]
  def self.up
    add_column :organizations, :identifier, :string
  end

  def self.down
    remove_column :organizations, :identifier
  end
end

class AddNotifiedToOrganizations < ActiveRecord::Migration[4.2]
  def self.up
    add_column :organizations, :notified, :boolean
  end

  def self.down
    remove_column :organizations, :notified
  end
end

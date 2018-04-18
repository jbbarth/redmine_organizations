class AddNotifiedToOrganizations < ActiveRecord::Migration
  def self.up
    add_column :organizations, :notified, :boolean
  end

  def self.down
    remove_column :organizations, :notified
  end
end

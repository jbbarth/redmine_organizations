class RenameFullnameColumn < ActiveRecord::Migration
  def self.up
    rename_column :organizations, :fullname, :name_with_parents
  end

  def self.down
    rename_column :organizations, :name_with_parents, :fullname
  end
end

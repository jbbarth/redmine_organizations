class IncreaseUsersLastnameLimit < ActiveRecord::Migration[4.2]
  def self.up
    unless Rails.env.test?
      change_column :users, :lastname, :string, :limit => nil, :default => "", :null => false
    end
  end

  def self.down
    change_column :users, :lastname, :string, :limit => 30, :default => "", :null => false
  end
end

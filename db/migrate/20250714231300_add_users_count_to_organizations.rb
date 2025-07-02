class AddUsersCountToOrganizations < ActiveRecord::Migration[6.1]
  def change
    add_column :organizations, :users_count, :integer, default: 0, null: false
  end
end

class IndexForeignKeysInUsers < ActiveRecord::Migration
  def change
    add_index :users, :organization_id
  end
end

class IndexForeignKeysInUsers < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :organization_id
  end
end

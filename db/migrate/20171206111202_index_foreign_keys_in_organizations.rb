class IndexForeignKeysInOrganizations < ActiveRecord::Migration[4.2]
  def change
    add_index :organizations, :parent_id
  end
end

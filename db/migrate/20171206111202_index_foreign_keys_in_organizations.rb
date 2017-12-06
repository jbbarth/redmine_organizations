class IndexForeignKeysInOrganizations < ActiveRecord::Migration
  def change
    add_index :organizations, :parent_id
  end
end

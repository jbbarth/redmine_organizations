class CreateOrganizations < ActiveRecord::Migration[4.2]
  def self.up
    create_table :organizations do |t|
      t.column :name, :string
      t.column :description, :text
      t.column :parent_id, :integer
      t.column :lft, :integer
      t.column :rgt, :integer
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :organizations
  end
end

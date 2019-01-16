class CreateOrganizationInvolvements < ActiveRecord::Migration[4.2]
  def self.up
    create_table :organization_involvements do |t|
      t.column :user_id, :integer, :null => false
      t.column :organization_membership_id, :integer, :null => false
    end
  end

  def self.down
    drop_table :organization_involvements
  end
end

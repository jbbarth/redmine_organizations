class RemoveOrganizationInvolvements < ActiveRecord::Migration
  def self.up
    # Should not be necessary, and will probably do nothing, but we don't want to lost members
    ActiveRecord::Base.connection.execute("select count(user_id) FROM organization_involvements INNER JOIN organization_memberships ON organization_memberships.id = organization_involvements.organization_membership_id").each do |result|
      Member.create(:user_id=>result["user_id"], :project_id=>result["project_id"])
    end
    drop_table :organization_involvements
  end

  def self.down
    create_table :organization_involvements do |t|
      t.column :user_id, :integer, :null => false
      t.column :organization_membership_id, :integer, :null => false
    end
  end
end

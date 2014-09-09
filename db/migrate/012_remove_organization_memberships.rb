class RemoveOrganizationMemberships < ActiveRecord::Migration
  def self.up
    drop_table :organization_memberships
  end

  def self.down
    create_table "organization_memberships", :force => true do |t|
      t.integer "organization_id", :null => false
      t.integer "project_id",      :null => false
    end
    add_index "organization_memberships", ["organization_id"], :name => "index_org_memberships_on_org_id"
    add_index "organization_memberships", ["project_id"], :name => "index_org_memberships_on_project_id"
  end
end

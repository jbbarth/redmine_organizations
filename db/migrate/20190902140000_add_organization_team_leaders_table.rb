class AddOrganizationTeamLeadersTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :organization_team_leaders do |t|
      t.column :organization_id, :integer, :null => false
      t.column :user_id, :integer, :null => false
    end unless ActiveRecord::Base.connection.table_exists? 'organization_team_leaders'
    add_index :organization_team_leaders, [:organization_id] unless ActiveRecord::Base.connection.index_exists?(:organization_team_leaders, [:organization_id])
    add_index :organization_team_leaders, [:user_id] unless ActiveRecord::Base.connection.index_exists?(:organization_team_leaders, [:user_id])
  end

  def self.down
    drop_table :organization_team_leaders
  end
end

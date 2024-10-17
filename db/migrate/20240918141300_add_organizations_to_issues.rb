class AddOrganizationsToIssues < ActiveRecord::Migration[4.2]

  def self.up
    create_table :issues_organizations do |t|
      t.column :organization_id, :integer, :null => false
      t.column :issue_id, :integer, :null => false
    end unless ActiveRecord::Base.connection.table_exists? 'issues_organizations'
    add_index :issues_organizations, [:organization_id] unless ActiveRecord::Base.connection.index_exists?(:issues_organizations, [:organization_id])
    add_index :issues_organizations, [:issue_id] unless ActiveRecord::Base.connection.index_exists?(:issues_organizations, [:issue_id])
  end

  def self.down
    drop_table :issues_organizations
  end

end

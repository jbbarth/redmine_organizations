class RemoveOrganizationInvolvements < ActiveRecord::Migration[4.2]
  def self.up
    # Migrating members and member's roles to standard tables, we don't want to lost members
    ActiveRecord::Base.connection.execute("select user_id, project_id, role_id FROM organization_involvements INNER JOIN organization_memberships ON organization_memberships.id = organization_involvements.organization_membership_id INNER JOIN organization_roles ON organization_memberships.id = organization_roles.organization_membership_id").each do |result|
      member = Member.where(user_id: result["user_id"], project_id: result["project_id"]).first_or_initialize
      unless member.roles.map(&:id).include?(result["role_id"].to_i)
        member.roles << Role.find(result["role_id"])
        member.save! if member.project.present? && member.user.present?
      end
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

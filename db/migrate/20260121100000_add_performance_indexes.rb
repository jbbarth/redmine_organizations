# frozen_string_literal: true

class AddPerformanceIndexes < ActiveRecord::Migration[7.2]
  def change
    add_index :issues, [:project_id, :status_id, :id],
              order: { id: :desc },
              name: 'index_issues_project_status_id_desc',
              if_not_exists: true

    add_index :issues, [:author_id, :assigned_to_id, :project_id],
              name: 'index_issues_author_assigned_project',
              if_not_exists: true

    add_index :issues, [:project_id, :is_private, :author_id],
              name: 'index_issues_project_private_author',
              if_not_exists: true

    add_index :enabled_modules, [:project_id],
              where: "name = 'issue_tracking'",
              name: 'index_enabled_modules_issue_tracking',
              if_not_exists: true

    add_index :issues_organizations, [:organization_id, :issue_id],
              name: 'index_issues_organizations_org_issue',
              if_not_exists: true unless index_exists?(:issues_organizations, [:organization_id, :issue_id])
  end
end

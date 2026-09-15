# frozen_string_literal: true

require "spec_helper"
require File.dirname(__FILE__) + '/../../lib/redmine_organizations/patches/project_patch'

describe "ProjectPatch" do
  fixtures :organizations, :users, :roles, :projects, :members, :member_roles

  it "should Project#users_by_role_and_organization" do
    u = Project.find(1).users_by_role_and_organization
    expect(u.keys.length).to eq 2
    assert u.keys.include?(Role.find(1))
    expect(u[Role.find(1)].keys.length).to eq 1
  end

  describe ".allowed_to_condition" do
    let(:user) { User.find(2) }
    let(:organization) { Organization.find(1) }
    let(:project) { Project.find('onlinestore') }
    let(:role) { Role.find(3) }

    before { user.update_column(:organization_id, organization.id) }

    it "does not raise when OrganizationNonMemberRole references a deleted project (orphan record)" do
      OrganizationNonMemberRole.create!(organization: organization, role: role, project: project)
      Project.delete(project.id) # bypass callbacks to create an orphan

      expect { Project.allowed_to_condition(user, :view_issues) }.not_to raise_error
    end

    it "destroys associated OrganizationNonMemberRole records when a project is destroyed" do
      OrganizationNonMemberRole.create!(organization: organization, role: role, project: project)

      expect { project.destroy }.to change { OrganizationNonMemberRole.count }.by(-1)
    end
  end

  describe ".allowed_to_condition with organization non-member roles" do
    fixtures :organizations, :users, :roles, :projects, :members, :member_roles,
             :trackers, :projects_trackers, :issue_statuses, :enumerations, :enabled_modules

    let(:user) { User.find(4) } # member of no project
    let(:project) { Project.find(5) } # private subproject of project 1
    let(:role) { Role.generate!(permissions: [:view_issues], issues_visibility: 'default') }

    before do
      user.update_column(:organization_id, 2)
      # Granted to the parent organization on the parent project
      OrganizationNonMemberRole.create!(organization_id: 1, role: role, project_id: 1)
      project.enable_module!(:issue_tracking)
      project.enable_module!(:time_tracking)
    end

    it "grants the permissions of the role on private subprojects" do
      expect(Project.allowed_to(user, :view_issues).ids).to include(project.id)
    end

    it "ignores the role for a permission it does not grant" do
      expect(Project.allowed_to(user, :view_time_entries).ids).not_to include(project.id)
    end

    it "applies the issues visibility of the role" do
      public_issue = Issue.generate!(project: project, author_id: 2)
      private_issue = Issue.generate!(project: project, author_id: 2, is_private: true)

      visible_ids = Issue.visible(user).ids
      expect(visible_ids).to include(public_issue.id)
      expect(visible_ids).not_to include(private_issue.id)
    end

    it "keeps the SQL condition consistent with User#allowed_to?" do
      %i[view_project view_issues view_time_entries view_wiki_pages].each do |permission|
        expected = Project.all.select { |p| user.allowed_to?(permission, p) }.map(&:id).sort
        expect(Project.allowed_to(user, permission).ids.sort).to eq(expected), "mismatch on #{permission}"
      end
    end

    it "loads the organization non-member roles once per user" do
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?('organization_non_member_roles') }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        3.times { Project.allowed_to_condition(user, :view_issues) }
      end
      expect(queries.size).to eq 1
    end
  end
end

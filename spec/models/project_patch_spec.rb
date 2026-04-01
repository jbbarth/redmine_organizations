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
end

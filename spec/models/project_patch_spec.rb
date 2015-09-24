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

  it "should test allowed_to_condition class method" do
    # test with and without exceptions through organizations memberships settings
    # TODO
  end
end

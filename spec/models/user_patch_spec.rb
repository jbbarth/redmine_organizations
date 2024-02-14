require "spec_helper"
require File.dirname(__FILE__) + '/../../lib/redmine_organizations/patches/user_patch'

describe "UserPatch" do

  fixtures :organizations, :organization_managers, :users, :roles

  before(:each) do
    User.find(1).update_attribute(:organization_id, 1)
    User.find(2).update_attribute(:organization_id, 2)
  end

  it "should test the allowed_to method"
  # test with and without exceptions through organizations memberships settings
  # TODO

  it "should return organization managers for a specific user" do
    expect(User.find(2).organization).to eq Organization.find(2)
    expect(User.find(2).managers).to eq [User.find(2), User.find(1)]
  end

  it "Update OrganizationManager, OrganizationTeamLeader tables, when deleting a user" do
    user = User.find(2)
    expect do
      user.destroy
    end.to change { OrganizationManager.count }.by(-1)
    .and change { OrganizationTeamLeader.count }.by(-1)
  end
end

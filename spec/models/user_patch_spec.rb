require "spec_helper"
require File.dirname(__FILE__) + '/../../lib/redmine_organizations/patches/user_patch'

describe "UserPatch" do
  # fixtures :organizations, :users, :roles, :projects, :members, :member_roles

  it "should test the allowed_to method" do
    # test with and without exceptions through organizations memberships settings
    # TODO
  end
end

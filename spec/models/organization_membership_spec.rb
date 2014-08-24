require "spec_helper"
require "active_support/testing/assertions"

describe "OrganizationMembership" do
  include ActiveSupport::Testing::Assertions
  fixtures :organizations, :organization_memberships, :organization_involvements, :organization_roles,
           :users, :roles, :projects, :members, :member_roles

  it "should test_organization_tree_sorting" do
    o = Organization.create(:name => "Team C", :parent_id => 1)
    o.left_sibling.name.should == "Team B"
    o.update_attributes(:name => "Team 0")
    o.right_sibling.name.should == "Team A"
    assert_nil o.left_sibling
    o.update_attributes(:name => "A new org", :parent_id => nil)
    o.right_sibling.name.should == "Org A"
  end

  it "should OrganizationMembership#destroy" do
    o = OrganizationMembership.find(3)
    assert_difference 'Organization.find(1).projects.count', -1 do
      o.destroy
    end
  end
end

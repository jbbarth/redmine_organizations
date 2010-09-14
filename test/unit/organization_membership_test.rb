require File.dirname(__FILE__) + '/../test_helper'

class OrganizationMembershipTest < ActiveSupport::TestCase
  fixtures :organizations, :organization_memberships

  test "test_organization_tree_sorting" do
    o = Organization.create(:name => "Team C", :parent_id => 1)
    assert_equal "Team B", o.left_sibling.name
    o.update_attributes(:name => "Team 0")
    assert_equal "Team A", o.right_sibling.name
    assert_nil o.left_sibling
    o.update_attributes(:name => "A new org", :parent_id => nil)
    assert_equal "Org A", o.right_sibling.name
  end
  
  test "OrganizationMembership#destroy" do
    o = OrganizationMembership.find(3)
    assert_difference 'Organization.find(1).projects.count', -1 do
      o.destroy
    end
  end
end

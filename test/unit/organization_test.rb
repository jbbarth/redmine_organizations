require File.dirname(__FILE__) + '/../test_helper'

class OrganizationTest < ActiveSupport::TestCase
  fixtures :organizations

  def test_organization_tree_sorting
    o = Organization.create(:name => "Org A / Team C", :parent_id => 1)
    assert_equal "Org A / Team B", o.left_sibling.name
    o.update_attributes(:name => "Org A / Team 0")
    assert_equal "Org A / Team A", o.right_sibling.name
    assert_nil o.left_sibling
    o.update_attributes(:name => "A new org", :parent_id => nil)
    assert_equal "Org A", o.right_sibling.name
  end
end

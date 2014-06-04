require File.dirname(__FILE__) + '/../test_helper'

class OrganizationTest < ActiveSupport::TestCase
  fixtures :organizations, :organization_memberships, :organization_roles,
           :users, :roles, :projects, :members, :member_roles

  test "test_organization_tree_sorting" do
    o = Organization.create(:name => "Team C", :parent_id => 1)
    assert_equal "Team B", o.left_sibling.name
    o.update_attributes(:name => "Team 0")
    assert_equal "Team A", o.right_sibling.name
    assert_nil o.left_sibling
    o.update_attributes(:name => "A new org", :parent_id => nil)
    assert_equal "Org A", o.right_sibling.name
  end
  
  test "Organization#fullname" do
    assert_equal "Org A", Organization.find(1).fullname
    assert_equal "Org A/Team A", Organization.find(2).fullname
  end

  test "Organization#direction" do
    assert Organization.find(1).direction?
    assert ! Organization.find(2).direction?
    assert_equal 1, Organization.find(2).direction_organization.id
  end

  test 'organization_validations' do
    already_taken_orga = Organization.new(name: "Team A", parent_id: 1) #orga with same name and same parent already exists
    assert !already_taken_orga.valid?
    assert_match /already been taken/, already_taken_orga.errors[:name].first

    same_name_orga = Organization.new(name: "Team A", parent_id: 3) #same name but different parent : OK
    assert same_name_orga.valid?
  end
end

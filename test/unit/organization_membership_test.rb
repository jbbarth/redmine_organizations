require File.dirname(__FILE__) + '/../test_helper'

class OrganizationMembershipTest < ActiveSupport::TestCase
  fixtures :organizations, :organization_memberships, :organization_roles,
           :users, :roles, :projects, :members, :member_roles

  def setup
    @organization = Organization.find(1)
    @project = Project.find(5)
    @user = User.find(3)
    @user.organization = @organization
    @user.save
    @role1 = Role.find(1)
    @role2 = Role.find(2)
  end

  test "OrganizationMembership#after_save updates correctly memberships" do
    assert ! @user.member_of?(@project)
    #create an organization membership
    m = OrganizationMembership.create!(:organization => @organization, :project => @project, :roles => [@role1, @role2])
    assert ! @user.reload.member_of?(@project)
    #add a user
    assert_difference "Member.count", +1 do
      OrganizationMembership.add_member(@user, @project.id, m.roles.map(&:id))
    end
    assert_include @user, m.users
    assert @user.reload.member_of?(@project), "User #{@user.id} should be member of project #{@project.id}"
    assert_equal [1,2], @user.roles_for_project(@project).map(&:id)
    #update its roles
    m.roles = [@role1]
    m.save
    assert_equal [1], @user.reload.roles_for_project(@project).map(&:id)
  end

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

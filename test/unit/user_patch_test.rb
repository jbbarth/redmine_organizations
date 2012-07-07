require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/redmine_organizations/patches/project_patch'

class ProjectPatchTest < ActiveSupport::TestCase
  fixtures :organizations, :organization_memberships, :organization_involvements, :organization_roles,
           :users, :roles, :projects, :members, :member_roles
  
  test "User#update_membership_through_organization" do
    @project = Project.find(1)
    @user = User.find(1)
    assert !@user.member_of?(@project)
    @om = OrganizationMembership.find(1)
    assert_equal 1, @om.project_id
    assert_equal [1,2], @om.role_ids.sort
    #let's update!
    @user.update_membership_through_organization(@om)
    assert @user.reload.member_of?(@project)
    assert_equal [1,2], @user.roles_for_project(@project).map(&:id)
  end
end

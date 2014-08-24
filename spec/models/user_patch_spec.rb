require "spec_helper"
require File.dirname(__FILE__) + '/../../lib/redmine_organizations/patches/project_patch'

describe "ProjectPatch" do
  fixtures :organizations, :organization_memberships, :organization_involvements, :organization_roles,
           :users, :roles, :projects, :members, :member_roles

  it "should User#update_membership_through_organization" do
    @project = Project.find(1)
    @user = User.find(1)
    assert !@user.member_of?(@project)
    @om = OrganizationMembership.find(1)
    @om.project_id.should == 1
    @om.role_ids.sort.should == [1,2]
    #let's update!
    @user.update_membership_through_organization(@om)
    assert @user.reload.member_of?(@project)
    @user.roles_for_project(@project).map(&:id).should == [1,2]
  end
end

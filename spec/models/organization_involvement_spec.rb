require "spec_helper"

describe "OrganizationInvolvement" do
  fixtures :organizations, :organization_memberships, :organization_involvements, :organization_roles,
           :users, :roles, :projects, :members, :member_roles

  before do
    @organization = Organization.find(1)
    @project = Project.find(5)
    @user = User.find(3)
    @role1 = Role.find(1)
    @role2 = Role.find(2)
  end

  it "should OrganizationInvolvement#after_save updates correctly memberships" do
    assert ! @user.member_of?(@project)
    #create an organization membership
    m = OrganizationMembership.create!(:organization => @organization, :project => @project, :roles => [@role1, @role2])
    assert ! @user.reload.member_of?(@project)
    #add a user
    m.users << @user
    m.save
    assert @user.reload.member_of?(@project)
    @user.roles_for_project(@project).map(&:id).should == [1,2]
    #update its roles
    m.roles = [@role1]
    m.save
    @user.reload.roles_for_project(@project).map(&:id).should == [1]
    #remove involved users
    m.user_ids = []
    m.save
    assert ! @user.reload.member_of?(@project)
  end
end

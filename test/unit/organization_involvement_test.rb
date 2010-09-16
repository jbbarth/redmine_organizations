require File.dirname(__FILE__) + '/../test_helper'

class OrganizationInvolvementTest < ActiveSupport::TestCase
  fixtures :organizations, :organization_memberships

  def setup
    @organization = Organization.find(1)
    @project = Project.find(5)
    @user = User.find(1)
    @role1 = Role.find(1)
    @role2 = Role.find(2)
  end
  
  test "OrganizationInvolvement#after_save updates correctly memberships" do
    assert ! @user.member_of?(@project)
    #create an organization membership
    m = OrganizationMembership.create!(:organization => @organization, :project => @project, :roles => [@role1, @role2])
    assert ! @user.reload.member_of?(@project)
    #add a user
    m.users << @user
    m.save
    assert @user.reload.member_of?(@project)
    assert_equal [1,2], @user.roles_for_project(@project).map(&:id)
    #update its roles
    m.roles = [@role1]
    m.save
    assert_equal [1], @user.reload.roles_for_project(@project).map(&:id)
    #remove involved users
    m.users = []
    m.save
    assert ! @user.reload.member_of?(@project)
  end
  
  #test "Involvements through multiple organizations don't break other ones inherited roles" do
  def test_truc
    @user2 = User.find(3)
    @organization2 = Organization.find(2)
    assert ! @user.member_of?(@project)
    assert ! @user2.member_of?(@project)
    m1 = OrganizationMembership.create!(:organization => @organization, :project => @project,
                                        :roles => [@role1, @role2], :users => [@user])
    assert_equal [1,2], @user.reload.roles_for_project(@project).map(&:id)
    m2 = OrganizationMembership.create!(:organization => @organization2, :project => @project,
                                        :roles => [@role1], :users => [@user, @user2])
    assert_equal [1,2], @user.reload.roles_for_project(@project).map(&:id)
    assert_equal [1], @user2.reload.roles_for_project(@project).map(&:id)
  end
end

require File.dirname(__FILE__) + '/../test_helper'

class OrganizationsControllerTest < ActionController::TestCase
  def setup
    @request.session[:user_id] = 1
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:organizations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create organization" do
    assert_difference('Organization.count') do
      post :create, :organization => { }
    end

    assert_redirected_to organization_path(assigns(:organization))
  end

  test "should show organization" do
    get :show, :id => Organization.find(1).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => Organization.find(1).to_param
    assert_response :success
  end

  test "should update organization" do
    put :update, :id => Organization.find(1).to_param, :organization => { }
    assert_redirected_to organization_path(assigns(:organization))
  end

  test "should destroy organization" do
    assert_difference('Organization.count', -1) do
      delete :destroy, :id => Organization.find(3).to_param
    end

    assert_redirected_to organizations_path
  end
  
  test "should copy organizations and involvements from an other user" do
    user2 = User.find(2)
    user2.organization_id = 1
    user2.save
    user3 = User.find(3)
    project2 = Project.find(2)
    #check user(2)
    assert_equal [1,2,5], user2.project_ids
    assert_equal [1], project2.organization_ids
    assert Organization.find(1).user_ids.include?(2)
    assert OrganizationInvolvement.all(:conditions => {:user_id => 2, :organization_memberships => {:project_id => 2}},
                                       :include => [:organization_membership]).any?
    #check not user(3)
    assert !Organization.find(1).user_ids.include?(3)
    assert !OrganizationInvolvement.all(:conditions => {:user_id => 3, :organization_memberships => {:project_id => 2}},
                                        :include => [:organization_membership]).any?
    assert !user3.member_of?(project2)
    #copy
    post :copy_user, :copy => {:user_from => 2, :user_to => 3}
    assert_redirected_to '/users/3/edit/organizations'
    #check user(3)
    assert OrganizationInvolvement.all(:conditions => {:user_id => 3, :organization_memberships => {:project_id => 2}},
                                       :include => [:organization_membership]).any?
    assert User.find(3).member_of?(Project.find(2)) #user3/project2 don't work!
  end
end

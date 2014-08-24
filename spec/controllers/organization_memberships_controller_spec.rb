require "spec_helper"
require "active_support/testing/assertions"

describe OrganizationMembershipsController do
  include ActiveSupport::Testing::Assertions
  it "should should create organization membership" do
    @request.session[:user_id] = 1
    assert_difference 'Organization.find(1).projects.count', 1 do
      post :create, :membership => {:organization_id => 1, :project_id => 5, :role_ids => ['1', '2']}
    end
  end

  it "should should update organization membership" do
    @request.session[:user_id] = 1
    put :update, :id => 1, :membership => { :role_ids => ['1', '3']}
    OrganizationMembership.find(1).role_ids.sort.should == [1,3]
  end

  it "should should destroy membership" do
    @request.session[:user_id] = 1
    assert_difference 'Organization.find(1).projects.count', -1 do
      delete :destroy, :id => 3
    end
  end

  it "should should destroy membership inside a project" do
    @request.session[:user_id] = 2
    assert_difference 'Organization.find(1).projects.count', -1 do
      delete :destroy_in_project, :project_id => 2, :id => 3
    end
    response.should redirect_to('/projects/onlinestore/settings/members')
  end
end

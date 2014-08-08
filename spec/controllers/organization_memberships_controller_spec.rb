require "spec_helper"
require "active_support/testing/assertions"

describe OrganizationMembershipsController do
  include ActiveSupport::Testing::Assertions
  it "should should create organization membership" do
    @request.session[:user_id] = 1
    assert_difference 'Organization.find(1).projects.count', 1 do
      post :create, :membership => {:organization_id => 1, :project_id => 5}
    end
  end

  it "should should update organization membership" do
    @request.session[:user_id] = 1
<<<<<<< HEAD:spec/controllers/organization_memberships_controller_spec.rb
    put :update, :id => 1, :membership => { :role_ids => ['1', '3']}
    OrganizationMembership.find(1).role_ids.sort.should == [1,3]
=======

    put :update, :id => 1, :membership => { :organization_id => 3}

    assert_equal 3, OrganizationMembership.find(1).organization_id
>>>>>>> Remove OrganizationRole class:test/functional/organization_memberships_controller_test.rb
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
      delete :destroy_in_project, :project_id => 2, :organization_id => 1
    end
<<<<<<< HEAD:spec/controllers/organization_memberships_controller_spec.rb
    response.should redirect_to('/projects/onlinestore/settings/members')
=======
    assert_redirected_to '/projects/2/settings/members'
>>>>>>> Remove OrganizationRole class:test/functional/organization_memberships_controller_test.rb
  end
end

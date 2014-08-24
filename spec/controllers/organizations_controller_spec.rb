require "spec_helper"
require "active_support/testing/assertions"

describe OrganizationsController do
  render_views
  include ActiveSupport::Testing::Assertions
  before do
    @request.session[:user_id] = 1
  end

  it "should should get index" do
    get :index
    response.should be_success
    assert_not_nil assigns(:organizations)
  end

  it "should should get new" do
    get :new
    response.should be_success
  end

  it "should should create organization" do
    assert_difference('Organization.count') do
      post :create, organization: { name: "orga-A" }
    end

    response.should redirect_to(organization_path(assigns(:organization)))
  end

  it "should should show organization" do
    get :show, :id => Organization.find(1).to_param
    response.should be_success
  end

  it "should should get edit" do
    get :edit, :id => Organization.find(1).to_param
    response.should be_success
  end

  it "should should update organization" do
    put :update, :id => Organization.find(1).to_param, :organization => { }
    response.should redirect_to(organization_path(assigns(:organization)))
  end

  it "should should destroy organization" do
    assert_difference('Organization.count', -1) do
      delete :destroy, :id => Organization.find(3).to_param
    end

    response.should redirect_to(organizations_path)
  end

  it "should autocomplete for users" do
    get :autocomplete_for_user, :id => 1, :q => "adm"
    response.should be_success
    assert response.body.include?("Admin")
    assert !response.body.include?("John")
  end

  it "should should NOT create organizations with same names and parents" do
    assert_no_difference('Organization.count') do
      post :create, organization: {name: "Team A", parent_id: 1}
    end
  end

  it "should should create organizations with same names but different parents" do
    assert_difference('Organization.count') do
      post :create, organization: {name: "Team A", parent_id: 3}
    end
  end

end

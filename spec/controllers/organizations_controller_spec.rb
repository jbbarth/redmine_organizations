require "spec_helper"
require "active_support/testing/assertions"

describe OrganizationsController, :type => :controller do

  fixtures :organizations

  render_views

  include ActiveSupport::Testing::Assertions

  before do
    @request.session[:user_id] = 1
  end

  it "should get index" do
    get :index
    expect(response).to be_successful
    refute_nil assigns(:organizations)
  end

  it "should get new" do
    get :new
    expect(response).to be_successful
  end

  it "should create organization" do
    assert_difference('Organization.count') do
      post :create, params: {organization: {name: "orga-A"}}
    end

    expect(response).to redirect_to(organization_path(assigns(:organization)))
  end

  it "should show organization" do
    get :show, params: {:id => Organization.find(1).to_param}
    expect(response).to be_successful
  end

  it "should get edit" do
    get :edit, params: {:id => Organization.find(1).to_param}
    expect(response).to be_successful
  end

  it "should update organization" do
    put :update, params: {:id => Organization.find(1).to_param, :organization => {}}
    expect(response).to redirect_to(organization_path(assigns(:organization)))
  end

  it "should destroy organization" do
    assert_difference('Organization.count', -1) do
      delete :destroy, params: {:id => Organization.find(3).to_param}
    end

    expect(response).to redirect_to(organizations_path)
  end

  it "should autocomplete for users" do
    get :autocomplete_for_user, params: {:id => 1, :q => "adm"}
    expect(response).to be_successful
    assert response.body.include?("Admin")
    assert !response.body.include?("John")
  end

  it "should NOT create organizations with same names and parents" do
    assert_no_difference('Organization.count') do
      post :create, params: {organization: {name: "Team A", parent_id: 1}}
    end
  end

  it "should create organizations with same names but different parents" do
    assert_difference('Organization.count') do
      post :create, params: {organization: {name: "Team A", parent_id: 3}}
    end
  end

  describe "add_users method" do
    it "should add a user to the organization" do
      assert_difference 'Organization.find(1).users.count', 1 do
        post :add_users, params: {id: 1, user_ids: ["8"]}
      end
    end
    it "should add several users at a time to the organization" do
      assert_difference 'Organization.find(1).users.count', 2 do
        post :add_users, params: {id: 1, user_ids: ["7", "8"]}
      end
    end
  end

  describe "memberships methods" do

    before do
      @request.session[:user_id] = 1
      members = Member.where("project_id = ?", 2)
      members.each do |m|
        if m.user.present?
          m.user.organization_id = 1
          m.user.save!
        end
      end
    end

    it "shoud display the organization when adding a user"

    it "shoud update organization roles in a project"
=begin
    do
      users_ids = Project.find(2).members.map(&:user_id)
      users_ids << 1
      assert_difference 'Project.find(2).members.count', +1 do
        put :update_roles, 'membership' => {user_ids: users_ids, role_ids: [2]}, :project_id => 2, organization_id: 1
      end
      # TODO Test presence of new roles
      expect(response).to redirect_to('/projects/2/settings/members')
    end
=end

  end

end

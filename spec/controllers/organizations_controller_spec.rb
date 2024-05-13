# frozen_string_literal: true

require "spec_helper"
require "active_support/testing/assertions"

describe OrganizationsController, :type => :controller do
  fixtures :organizations, :organization_managers, :users,
           :organization_team_leaders, :members, :member_roles, :roles

  render_views

  include ActiveSupport::Testing::Assertions

  describe 'Admin actions' do
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

    it "delete an organization should set user.organization_id to nil" do
      user = User.find(5)
      user.organization = Organization.find(3)
      user.save
      delete :destroy, params: {:id => Organization.find(3).to_param}
      user.reload
      assert_equal user.organization_id, nil
    end

    it "should autocomplete for users" do
      get :autocomplete_for_user, params: {:id => 2, :q => "adm"}
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

    it "Changing name of parent organization should update full_name and identifier of its children" do
      org = Organization.find(1)
      new_name = "name_test"
      # Fill in the name_with_parents of the children of organization, because they are not filled in by the fixture
      org.children.each do |child|
        child.name_with_parents = org.name + Organization::SEPARATOR + child.name
        child.save
      end

      put :update, params: {id: org.identifier, organization: { name: new_name }}
      org.reload

      org.children.each do |child|
        assert_equal child.name_with_parents, new_name + Organization::SEPARATOR + child.name
        assert_equal child.identifier, (new_name + Organization::SEPARATOR + child.name).parameterize
      end
    end
  end

  describe "Manager actions" do
    before do
      @request.session[:user_id] = 2
    end

    it "should get new" do
      get :new
      expect(response).to be_successful
    end

    it "should forbid access to new method if non manager" do
      @request.session[:user_id] = 3
      get :new
      expect(response.status).to eq 403 # Forbidden
    end

    it "should get edit if user is a manager of the organization" do
      get :edit, params: {:id => Organization.find(2).to_param}
      expect(response).to be_successful
    end

    it "should not get edit if not a manager of the organization" do
      get :edit, params: {:id => Organization.find(1).to_param}
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "add_users method" do
    before do
      @request.session[:user_id] = 1
    end

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

  describe "GET #show/api" do
    let(:organization_1) { Organization.find(1) }
    let(:organization_2) { Organization.find(2) }

    before do
      Setting.rest_api_enabled = '1'
      request.headers['Authorization'] = ActionController::HttpAuthentication::Basic.encode_credentials("admin", "admin")
      User.find(1).update_attribute('organization_id', 1)
      User.find(4).update_attribute('organization_id', 1)
      User.find(2).update_attribute('organization_id', 2)
      User.find(7).update_attribute('organization_id', 2)
    end

    it "returns a success response" do
      get :show, params: {:id => organization_1.to_param,   :format => :json }
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it "renders the show view" do
      get :show, params: { id: organization_1.to_param, format: :json }
      expect(response).to render_template(:show)
    end

    it "returns organization details in JSON format" do
      get :show, params: { id: organization_2.to_param, format: :json }
      expect(response).to have_http_status(:success)

      parent_id = organization_2.parent_id
      json_response = JSON.parse(response.body)

      json_organization = json_response["organization"]
      expect(json_organization['id']).to eq(organization_2.id)
      expect(json_organization['name']).to eq(organization_2.name)
      expect(json_organization['description']).to eq(organization_2.description)
      expect(json_organization['parent']['id']).to eq(parent_id)
      expect(json_organization['parent']['name']).to eq(Organization.find(parent_id).fullname)
      expect(json_organization['mail']).to eq(organization_2.mail)
      expect(json_organization['direction']).to eq(organization_2.direction)
      expect(json_organization['name_with_parents']).to eq(organization_2.name_with_parents)
      expect(json_organization['top_department_in_ldap']).to eq(organization_2.top_department_in_ldap)
    end

    it "returns organization users in JSON format" do
      get :show, params: {:id => organization_1.to_param, :include => ["users"], :format => 'json' }
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      expect(json_response["organization"]['users'].count).to eq(2)

      users_in_response = json_response["organization"]['users']
      user_1 = users_in_response.find { |user| user['id'] == 1 }
      expect(user_1["manager"]).to eq(true)
      expect(user_1["team_leader"]).to eq(true)

      user_2 = users_in_response.find { |user| user['id'] == 4 }
      expect(user_2["manager"]).to eq(false)
      expect(user_2["team_leader"]).to eq(false)
    end

    it "returns a 404 error when the organization does not exist" do
      get :show, params: { id: 80 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #index/api" do
    let(:organizations) { Organization.all }
    before do
      Setting.rest_api_enabled = '1'
      request.headers['Authorization'] = ActionController::HttpAuthentication::Basic.encode_credentials("admin", "admin")
      User.find(1).update_attribute('organization_id', 1)
      User.find(4).update_attribute('organization_id', 1)
      User.find(2).update_attribute('organization_id', 2)
      User.find(7).update_attribute('organization_id', 2)
    end

    it "returns a success response" do
      get :index, params: { :format => :json }
      expect(response).to be_successful
      expect(response).to have_http_status(200)
    end

    it "renders the index view" do
      get :index, params: { format: :json }
      expect(response).to render_template(:index)
    end

    it "returns organizations details in JSON format" do
      get :index, params: { format: :json }

      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response["organizations"].count).to eq(Organization.count)

      organizations.each do |organization|
        json_organization = json_response["organizations"].find { |org| org["id"] == organization.id }

        expect(json_organization["name"]).to eq(organization.name)
        expect(json_organization["description"]).to eq(organization.description)
        expect(json_organization['parent']['id']).to eq(organization.parent_id) if json_organization['parent'].present?
        expect(json_organization["mail"]).to eq(organization.mail)
        expect(json_organization["direction"]).to eq(organization.direction)
        expect(json_organization["name_with_parents"]).to eq(organization.name_with_parents)
        expect(json_organization["top_department_in_ldap"]).to eq(organization.top_department_in_ldap)

      end
    end

    it "returns organizations users in JSON format" do
      get :index, params: { include: ["users"], format: 'json' }

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)

      json_response["organizations"].each_with_index do |json_organization, index|
        organization = organizations[index]

        json_users = json_organization["users"]
        expect(json_users.count).to eq(organization.users.count)

        organization.users.each do |user|
          json_user = json_users.find { |u| u["id"] == user.id }
          expect(json_user).to_not be_nil
        end
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

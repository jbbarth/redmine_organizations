require "spec_helper"

describe OrganizationsController, :type => :controller do

  fixtures :organizations, :organization_managers, :users,
           :organization_team_leaders, :members, :member_roles, :roles

  render_views

  describe 'Admin actions' do
    before do
      @request.session[:user_id] = 1
    end

    it "should get index" do
      get :index
      expect(response).to be_successful
      expect(assigns(:organizations)).not_to be_nil
    end

    it "should get new" do
      get :new
      expect(response).to be_successful
    end

    it "should create organization" do
      expect {
        post :create, params: {organization: {name: "orga-A"}}
      }.to change { Organization.count }.by(1)

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
      expect {
        delete :destroy, params: {:id => Organization.find(3).to_param}
      }.to change { Organization.count }.by(-1)

      expect(response).to redirect_to(organizations_path)
    end

    it "delete an organization should set user.organization_id to nil" do
      user = User.find(5)
      user.organization = Organization.find(3)
      user.save
      delete :destroy, params: {:id => Organization.find(3).to_param}
      user.reload
      expect(user.organization_id).to be_nil
    end

    it "should autocomplete for users" do
      get :autocomplete_for_user, params: {:id => 2, :q => "adm"}
      expect(response).to be_successful
      expect(response.body).to include("Admin")
      expect(response.body).not_to include("John")
    end

    it "should NOT create organizations with same names and parents" do
      expect {
        post :create, params: {organization: {name: "Team A", parent_id: 1}}
      }.not_to change { Organization.count }
    end

    it "should create organizations with same names but different parents" do
      expect {
        post :create, params: {organization: {name: "Team A", parent_id: 3}}
      }.to change { Organization.count }.by(1)
    end

    it "Changing name of parent organization should update full_name and identifier of its children" do
      org = Organization.find(1)
      new_name = "name_test"
      #Fill in the name_with_parents of the children of organization, because they are not filled in by the fixture
      org.children.each do |child|
        child.name_with_parents = org.name + Organization::SEPARATOR + child.name
        child.save
      end

      put :update, params: {id: org.identifier, organization: { name: new_name }}
      org.reload

      org.children.each do |child|
        expect(child.name_with_parents).to eq(new_name + Organization::SEPARATOR + child.name)
        expect(child.identifier).to eq((new_name + Organization::SEPARATOR + child.name).parameterize)
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
      expect {
        post :add_users, params: {id: 1, user_ids: ["8"]}
      }.to change { Organization.find(1).users.count }.by(1)
    end

    it "should add several users at a time to the organization" do
      expect {
        post :add_users, params: {id: 1, user_ids: ["7", "8"]}
      }.to change { Organization.find(1).users.count }.by(2)
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

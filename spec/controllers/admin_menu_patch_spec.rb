require "spec_helper"

describe "AdminMenuPatch", :type => :controller do

  render_views

  fixtures :users, :members, :member_roles, :roles, :projects

  before do
    @controller = AdminController.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end

  it "should hide groups menu if option is selected" do
    Setting["plugin_redmine_organizations"]["hide_groups_admin_menu"] = "1"
    get :index
    expect(response.body).to_not include(groups_path)
  end

  it "should display groups menu if option is not selected" do
    Setting["plugin_redmine_organizations"]["hide_groups_admin_menu"] = "0"
    get :index
    expect(response.body).to include(groups_path)
  end
end

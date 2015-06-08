require "spec_helper"

describe "UsersAdminPatch", :type => :controller do
  render_views
  before do
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end

  it "should hide groups tab if option is selected" do
    Setting["plugin_redmine_organizations"]["hide_groups_admin_menu"] = "1"
    get :edit, :id => 3
    assert_select "a[href='/users/3/edit?tab=groups']", false
  end

  it "should display groups tab if option is not selected" do
    Setting["plugin_redmine_organizations"]["hide_groups_admin_menu"] = ""
    get :edit, :id => 3
    assert_select "a[href='/users/3/edit?tab=groups']"
  end
end

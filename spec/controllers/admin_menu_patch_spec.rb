require "spec_helper"

describe "AdminMenuPatch", :type => :controller do
  render_views
  before do
    @controller = AdminController.new
    @request    = ActionDispatch::TestRequest.create
    @response   = ActionDispatch::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end

  it "should hide groups menu if option is selected" do
    Setting["plugin_redmine_organizations"]["hide_groups_admin_menu"] = "1"
    get :index
    assert_select "a[href='/groups']", false
  end

  it "should display groups menu if option is not selected" do
    Setting["plugin_redmine_organizations"]["hide_groups_admin_menu"] = "0"
    get :index
    assert_select "a[href='/groups']"
  end
end

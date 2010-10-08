require File.dirname(__FILE__) + '/../test_helper'

class AdminMenuPatchTest < ActionController::TestCase
  def setup
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end
  
  test "should hide groups menu if option is selected" do
    Setting["plugin_redmine_organizations"]["hide_groups_admin_menu"] = "1"
    get :index
    assert_no_tag :tag => 'a', :attributes => { :href => "/groups" }
  end
  
  test "should display groups menu if option is not selected" do
    Setting["plugin_redmine_organizations"]["hide_groups_admin_menu"] = ""
    get :index
    assert_tag :tag => 'a', :attributes => { :href => "/groups" }
  end
end

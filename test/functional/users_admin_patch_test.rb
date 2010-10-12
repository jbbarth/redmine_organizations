require File.dirname(__FILE__) + '/../test_helper'

class UsersAdminPatchTest < ActionController::TestCase
  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end
  
  test "should hide groups tab if option is selected" do
    Setting["plugin_redmine_organizations"]["hide_groups_admin_menu"] = "1"
    get :edit, :id => 3
    assert_no_tag :tag => 'a', :attributes => { :href => "/users/3/edit/groups" }
  end
  
  test "should display groups tab if option is not selected" do
    Setting["plugin_redmine_organizations"]["hide_groups_admin_menu"] = ""
    get :edit, :id => 3
    assert_tag :tag => 'a', :attributes => { :href => "/users/3/edit/groups" }
  end
end

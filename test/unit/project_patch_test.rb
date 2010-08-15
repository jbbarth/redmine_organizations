require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/redmine_organizations/patches/project_patch'

class ProjectPatchTest < ActiveSupport::TestCase
  fixtures :organizations, :projects
  
  test "Project#users_by_role_and_organization" do
    u = Project.find(1).users_by_role_and_organization
    assert_equal 2, u.keys.length
    assert u.keys.include?(Role.find(1))
    assert_equal 1, u[Role.find(1)].keys.length
  end
end

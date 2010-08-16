require File.dirname(__FILE__) + '/../../test_helper'
require 'action_view/test_case'

class OrganizationsHelperTest < HelperTestCase
  include ApplicationHelper
  include OrganizationsHelper
  
  fixtures :all
  
  test "test rendering of link_to_organization" do
    link_1 = %(<a href="/organizations/1">Org A</a>)
    link_2 = %(<a href="/organizations/2">Team A</a>)
    assert_equal link_2, link_to_organization(Organization.find(2), :fullname=>false)
    assert_equal "#{link_1}/#{link_2}", link_to_organization(Organization.find(2))
  end
end

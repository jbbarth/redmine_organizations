require File.dirname(__FILE__) + '/../../test_helper'
require 'action_view/test_case'

class OrganizationsHelperTest < HelperTestCase
  include ApplicationHelper
  include OrganizationsHelper
  
  fixtures :all
  
  test "test rendering of link_to_organization" do
    link_1 = %(<a href="/organizations/1" title="Org A">Org A</a>)
    link_2 = %(<a href="/organizations/2" title="Org A/Team A">Team A</a>)
    link_3 = %(<a href="/organizations/2">Org A/Team A</a>)
    org = Organization.find(2)
    assert_equal link_2, link_to_organization(org, :fullname=>false)
    assert_equal "#{link_1}/#{link_2}", link_to_organization(org)
    assert_equal link_3, link_to_organization(org, :link_ancestors=>false)
  end
end

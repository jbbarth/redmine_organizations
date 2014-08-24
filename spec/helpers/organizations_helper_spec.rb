require "spec_helper"
require 'action_view/test_case'

describe OrganizationsHelper do
  include ApplicationHelper
  include ActionView::Helpers::UrlHelper

  fixtures :organizations

  it "should test rendering of link_to_organization" do
    link_1 = %(<a href="/organizations/1" title="Org A">Org A</a>)
    link_2 = %(<a href="/organizations/2" title="Org A/Team A">Team A</a>)
    link_3 = %(<a href="/organizations/2" title="Org A/Team A">Org A/Team A</a>)
    org = Organization.find(2)
    (link_to_organization(org, :fullname=>false)).should == link_2
    link_to_organization(org).should == "#{link_1}/#{link_2}"
    (link_to_organization(org, :link_ancestors=>false)).should == link_3
  end
end

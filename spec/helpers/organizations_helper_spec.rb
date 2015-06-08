require "spec_helper"
require 'action_view/test_case'

describe OrganizationsHelper do
  include ApplicationHelper
  include OrganizationsHelper
  include ActionView::Helpers::UrlHelper

  fixtures :organizations

  it "should test rendering of link_to_organization", :type => :helper do
    link_1 = %(<a title="Org A" href="/organizations/1">Org A</a>)
    link_2 = %(<a title="Org A/Team A" href="/organizations/2">Team A</a>)
    link_3 = %(<a title="Org A/Team A" href="/organizations/2">Org A/Team A</a>)
    org = Organization.find(2)
    expect(link_to_organization(org, :fullname=>false)).to eq link_2
    expect(link_to_organization(org)).to eq "#{link_1}/#{link_2}"
    expect(link_to_organization(org, :link_ancestors=>false)).to eq link_3
  end
end

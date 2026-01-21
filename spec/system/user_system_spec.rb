require "spec_helper"
require "active_support/testing/assertions"
require_relative "../support/login_user_spec_helpers"

RSpec.describe "/issue/id/edit", type: :system do
  include ActiveSupport::Testing::Assertions

  include ApplicationHelper
  include OrganizationsHelper
  include ActionView::Helpers::UrlHelper

  fixtures :organizations, :users, :roles, :projects, :members, :member_roles,
            :organization_managers, :organization_team_leaders
  before do
    log_user('admin', 'admin')
  end

  it "Should display delete links for member and team leader in profile page" do
    user = User.find(2)
    user.organization = Organization.find(2)
    user.save

    visit "/users/#{user.id}"

    organization_manager = user.organization_managers.map(&:organization).compact
    team_leader_organizations = user.organization_team_leaders.map(&:organization).compact

    organization_manager.each do |organization|
      expect(page).to have_link(nil, href: organizations_manager_path(id: organization.id, manager_id: user.id, page: "user"))
    end

    team_leader_organizations.each do |organization|
      expect(page).to have_link(nil, href: organizations_team_leader_path(id: organization.id, team_leader_id: user.id))
    end
  end
end
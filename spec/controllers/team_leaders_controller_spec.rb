require "spec_helper"

describe Organizations::TeamLeadersController, :type => :controller do

  include Redmine::I18n
  include Rails::Dom::Testing::Assertions
  include ActiveSupport::Testing::Assertions

  fixtures :organizations, :organization_managers, :users, :organization_team_leaders, :members, :member_roles, :roles

  render_views

  let(:email_field) { Redmine::VERSION::MAJOR >= 5 ? 'to' : 'bcc' }

  before(:each) do
    Setting.plain_text_mail = '1'
    Setting.default_language = 'fr'
    User.find(1).update_attribute('organization_id', 1)
    User.find(4).update_attribute('organization_id', 1)
    User.find(2).update_attribute('organization_id', 2)
    User.find(7).update_attribute('organization_id', 2)
  end

  it "should allow managers to set team-leaders in their organization and sub-organization" do
    @request.session[:user_id] = 2 # Member of organization #2

    OrganizationManager.create(user_id: 2, organization_id: 1)
    organization = Organization.find(2)
    expect(organization.team_leaders).to include(User.find(2))
    expect(organization.team_leaders).to_not include(User.find(7))

    assert_difference 'OrganizationTeamLeader.count', 1 do
      patch :update, params: { id: 2,
                               team_leader_ids: [2, 7] }
    end

    expect(response).to redirect_to(edit_organization_path(2, tab: 'users'))
    organization.reload
    expect(organization.team_leaders).to include(User.find(2))
    expect(organization.team_leaders).to include(User.find(7))
  end

  if Redmine::VERSION::MAJOR >= 5
    it "should forbid users from sub-organization to modify team-leaders in parents of their organization" do
      @request.session[:user_id] = 2 # Not Admin, member of organization #2
      expect { patch :update, params: { id: 1,
                                        team_leader_ids: [1] }
      }.to_not change { OrganizationTeamLeader.count }
      expect(response).to have_http_status(:forbidden) # 403
    end
  else
    # it raises a TemplateError in Redmine 4, which is fixed in Redmine 5
    # TODO: Remove this condition when we drop support of Redmine 4
  end

  it "should send a notification to new team leaders" do
    @request.session[:user_id] = 1 # Admin

    organization = Organization.find(1)
    expect(organization.team_leaders).to include(User.find(1))

    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      assert_difference 'OrganizationTeamLeader.count', 1 do
        patch :update, params: { id: 1,
                                 team_leader_ids: [1, 3] }
      end
    end

    expect(response).to redirect_to(edit_organization_path(1, tab: 'users'))

    mail = ActionMailer::Base.deliveries.last
    expect(mail[email_field].to_s).to include(User.find(3).mail)
    expect(mail[email_field].to_s).to_not include(User.find(1).mail)
    mail.parts.each do |part|
      expect(part.body.raw_source).to include("Redmine Admin vient de vous donner les droits de 'Chef d'équipe' pour l'orga")
      expect(part.body.raw_source).to_not include("vient de vous retirer")
    end

  end

  it "should send a notification to deleted team leaders" do
    @request.session[:user_id] = 1 # Admin

    organization = Organization.find(1)
    expect(organization.team_leaders).to include(User.find(1))

    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      assert_difference 'OrganizationTeamLeader.count', -1 do
        patch :update, params: { id: 1,
                                 team_leader_ids: [] }
      end
    end

    expect(response).to redirect_to(edit_organization_path(1, tab: 'users'))

    mail = ActionMailer::Base.deliveries.last
    expect(mail[email_field].to_s).to include(User.find(1).mail)
    expect(mail[email_field].to_s).to_not include(User.find(3).mail)
    mail.parts.each do |part|
      expect(part.body.raw_source).to include("Redmine Admin vient de vous retirer les droits de 'Chef d'équipe' pour l'orga")
      expect(part.body.raw_source).to_not include("vient de vous donner")
    end

  end

  it "should add a specific role to new team leaders" do
    @request.session[:user_id] = 1 # Admin
    with_settings :plugin_redmine_organizations => { 'default_team_leader_role' => '1' } do
      # Default team leader role

      organization = Organization.find(1)

      expect(organization.users).to include(User.find(4))
      expect(organization.team_leaders).to include(User.find(1))
      expect(organization.team_leaders).to_not include(User.find(4))

      assert_difference 'OrganizationTeamLeader.count', 1 do
        patch :update, params: { id: 1,
                                 team_leader_ids: [1, 4] }
      end

      organization.reload
      expect(organization.team_leaders).to include(User.find(4))
      expect(Project.find(5).users).to include User.find(4)
      expect(response).to redirect_to(edit_organization_path(1, tab: 'users'))
    end
  end

  it "should remove a specific role from deleted team leaders" do
    @request.session[:user_id] = 1 # Admin

    organization = Organization.find(1)

    expect(organization.users).to include(User.find(4))
    expect(organization.team_leaders).to include(User.find(1))
    expect(organization.team_leaders).to_not include(User.find(4))

    # First, set a new team leader
    assert_difference 'OrganizationTeamLeader.count', 1 do
      patch :update, params: { id: 1,
                               team_leader_ids: [1, 4] }
    end

    organization.reload
    expect(organization.users).to include(User.find(4))
    expect(organization.team_leaders).to include(User.find(1))
    expect(organization.team_leaders).to include(User.find(4))

    # Then, remove a team leader
    assert_difference 'OrganizationTeamLeader.count', -1 do
      patch :update, params: { id: 1,
                               team_leader_ids: [1] }
    end

    organization.reload
    expect(organization.team_leaders).to_not include(User.find(4))
    expect(Project.find(5).users).to_not include User.find(4)
  end

end

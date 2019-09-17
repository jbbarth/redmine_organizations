require "spec_helper"

describe Organizations::ManagersController, :type => :controller do

  include Redmine::I18n
  include Rails::Dom::Testing::Assertions
  include ActiveSupport::Testing::Assertions

  fixtures :organizations, :organization_managers, :users, :organization_team_leaders, :members, :member_roles

  render_views

  before(:each) do
    Setting.plain_text_mail = '1'
    Setting.default_language = 'fr'
    User.find(1).update_attribute('organization_id', 1)
    User.find(4).update_attribute('organization_id', 1)
    Setting["plugin_redmine_organizations"]["default_team_leader_role"] = 1
  end

  it "should send a notification to new managers" do
    @request.session[:user_id] = 1 # Admin

    organization = Organization.find(1)
    expect(organization.managers).to include(User.find(1))

    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      assert_difference 'OrganizationManager.count', 1 do
        patch :update, params: {id: 1,
                                manager_ids: [1, 3],
                                team_leader_ids: [1]}
      end
    end


    expect(response).to redirect_to(edit_organization_path(1, tab: 'users'))

    mail = ActionMailer::Base.deliveries.last
    expect(mail['bcc'].to_s).to include(User.find(3).mail)
    expect(mail['bcc'].to_s).to_not include(User.find(1).mail)
    mail.parts.each do |part|
      expect(part.body.raw_source).to include("vient de vous donner les droits de")
      expect(part.body.raw_source).to_not include("vient de vous retirer")
    end

  end

  it "should send a notification to deleted managers" do
    @request.session[:user_id] = 1 # Admin

    organization = Organization.find(1)
    expect(organization.managers).to include(User.find(1))

    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      assert_difference 'OrganizationManager.count', -1 do
        patch :update, params: {id: 1,
                                manager_ids: [],
                                team_leader_ids: [1]}
      end
    end

    expect(response).to redirect_to(edit_organization_path(1, tab: 'users'))

    mail = ActionMailer::Base.deliveries.last
    expect(mail['bcc'].to_s).to include(User.find(1).mail)
    expect(mail['bcc'].to_s).to_not include(User.find(3).mail)
    mail.parts.each do |part|
      expect(part.body.raw_source).to include("vient de vous retirer les droits de")
      expect(part.body.raw_source).to_not include("vient de vous donner")
    end

  end

  it "should send a notification to new team leaders" do
    @request.session[:user_id] = 1 # Admin

    organization = Organization.find(1)
    expect(organization.team_leaders).to include(User.find(1))

    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      assert_difference 'OrganizationTeamLeader.count', 1 do
        patch :update, params: {id: 1,
                                manager_ids: [1],
                                team_leader_ids: [1, 3]}
      end
    end


    expect(response).to redirect_to(edit_organization_path(1, tab: 'users'))

    mail = ActionMailer::Base.deliveries.last
    expect(mail['bcc'].to_s).to include(User.find(3).mail)
    expect(mail['bcc'].to_s).to_not include(User.find(1).mail)
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
        patch :update, params: {id: 1,
                                manager_ids: [1],
                                team_leader_ids: []}
      end
    end

    expect(response).to redirect_to(edit_organization_path(1, tab: 'users'))

    mail = ActionMailer::Base.deliveries.last
    expect(mail['bcc'].to_s).to include(User.find(1).mail)
    expect(mail['bcc'].to_s).to_not include(User.find(3).mail)
    mail.parts.each do |part|
      expect(part.body.raw_source).to include("Redmine Admin vient de vous retirer les droits de 'Chef d'équipe' pour l'orga")
      expect(part.body.raw_source).to_not include("vient de vous donner")
    end

  end

  it "should add a specific role to new team leaders" do
    @request.session[:user_id] = 1 # Admin

    organization = Organization.find(1)

    expect(organization.users).to include(User.find(4))
    expect(organization.team_leaders).to include(User.find(1))
    expect(organization.team_leaders).to_not include(User.find(4))

    assert_difference 'OrganizationTeamLeader.count', 1 do
      patch :update, params: {id: 1,
                              manager_ids: [1],
                              team_leader_ids: [1, 4]}
    end

    organization.reload
    expect(organization.team_leaders).to include(User.find(4))
    expect(Project.find(5).users).to include User.find(4)
    expect(response).to redirect_to(edit_organization_path(1, tab: 'users'))
  end

  it "should remove a specific role from deleted team leaders" do
    @request.session[:user_id] = 1 # Admin

    organization = Organization.find(1)

    expect(organization.users).to include(User.find(4))
    expect(organization.team_leaders).to include(User.find(1))
    expect(organization.team_leaders).to_not include(User.find(4))

    # First, set a new team leader
    assert_difference 'OrganizationTeamLeader.count', 1 do
      patch :update, params: {id: 1,
                              manager_ids: [1],
                              team_leader_ids: [1, 4]}
    end

    organization.reload
    expect(organization.users).to include(User.find(4))
    expect(organization.team_leaders).to include(User.find(1))
    expect(organization.team_leaders).to include(User.find(4))

    # Then, remove a team leader
    assert_difference 'OrganizationTeamLeader.count', -1 do
      patch :update, params: {id: 1,
                              manager_ids: [1],
                              team_leader_ids: [1]}
    end

    organization.reload
    expect(organization.team_leaders).to_not include(User.find(4))
    expect(Project.find(5).users).to_not include User.find(4)
  end

end

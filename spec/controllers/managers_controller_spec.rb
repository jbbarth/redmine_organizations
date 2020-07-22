require "spec_helper"

describe Organizations::ManagersController, :type => :controller do

  include Redmine::I18n
  include Rails::Dom::Testing::Assertions
  include ActiveSupport::Testing::Assertions

  fixtures :organizations, :organization_managers, :users, :members, :member_roles, :roles

  render_views

  before(:each) do
    Setting.plain_text_mail = '1'
    Setting.default_language = 'fr'
    User.find(1).update_attribute('organization_id', 1)
    User.find(4).update_attribute('organization_id', 1)
    User.find(2).update_attribute('organization_id', 2)
    User.find(7).update_attribute('organization_id', 2)
  end

  it "should allow managers to set other managers in their organization and sub-organization" do
    @request.session[:user_id] = 2 # Member of organization #2

    OrganizationManager.create(user_id: 2, organization_id: 1)
    organization = Organization.find(2)
    expect(organization.managers).to include(User.find(2))
    expect(organization.managers).to_not include(User.find(7))

    assert_difference 'OrganizationManager.count', 2 do
      post :create, params: {id: 2,
                             manager_ids: [2, 7]}
    end

    expect(response).to redirect_to(edit_organization_path(organization.id, tab: 'managers'))
    organization.reload
    expect(organization.managers).to include(User.find(2))
    expect(organization.managers).to include(User.find(7))
  end

  it "should forbid users from sub-organization to modify managers in parents of their organization" do
    @request.session[:user_id] = 2 # Not Admin, member of organization #2
    assert_no_difference 'OrganizationManager.count' do
      expect {post :create, params: {id: 1,
                                     manager_ids: [1, 2]}
      }.to raise_error(ActionView::Template::Error)
    end
    expect(response).to have_http_status(:forbidden) # 403
  end

  it "should send a notification to new managers" do
    @request.session[:user_id] = 1 # Admin

    organization = Organization.find(1)
    expect(organization.managers).to include(User.find(1))

    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      assert_difference 'OrganizationManager.count', 1 do
        post :create, params: {id: 1,
                               manager_ids: [3]}
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
        delete :destroy, params: {id: 1,
                                  manager_id: [1]}
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

end

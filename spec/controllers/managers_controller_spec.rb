require "spec_helper"

describe Organizations::ManagersController, :type => :controller do

  include Redmine::I18n

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

    expect {
      post :create, params: { id: 2,
                              manager_ids: [2, 7] }
    }.to change { OrganizationManager.count }.by(2)

    expect(response).to redirect_to(edit_organization_path(organization.identifier, tab: 'managers'))
    organization.reload
    expect(organization.managers).to include(User.find(2))
    expect(organization.managers).to include(User.find(7))
  end

  it "should delete manager from an organization" do
    @request.session[:user_id] = 1
    expect do
        delete :destroy, :params => {
          :manager_id => 2,
          :page => "user",
          :id => 2
        }, format: :js
      end.to change { OrganizationManager.count }.by(-1)
  end

  if Redmine::VERSION::MAJOR >= 5
    it "should forbid users from sub-organization to modify managers in parents of their organization" do
      @request.session[:user_id] = 2 # Not Admin, member of organization #2
      expect {
        post :create, params: { id: 1,
                                manager_ids: [1, 2] }
      }.to_not change { OrganizationManager.count }
      expect(response).to have_http_status(:forbidden) # 403
    end
  else
    # it raises a TemplateError in Redmine 4, which is fixed in Redmine 5
    # TODO: Remove this condition when we drop support of Redmine 4
  end


  pending "should send a notification to new managers" do
    @request.session[:user_id] = 1 # Admin
    ActionMailer::Base.deliveries.clear

    organization = Organization.find(1)
    expect(organization.managers).to include(User.find(1))

    expect {
      post :create, params: { id: 1,
                              manager_ids: [3] }
    }.to change { OrganizationManager.count }.by(1)
      .and change { ActionMailer::Base.deliveries.size }.by(1)

    expect(response).to redirect_to(edit_organization_path('org-a', tab: 'managers'))

    mail = ActionMailer::Base.deliveries.last
    expect(mail['to'].to_s).to include(User.find(3).mail)
    expect(mail['to'].to_s).to_not include(User.find(1).mail)
    mail.parts.each do |part|
      expect(part.body.raw_source).to include("vient de vous donner les droits de")
      expect(part.body.raw_source).to_not include("vient de vous retirer")
    end

  end

  pending "should send a notification to deleted managers" do
    @request.session[:user_id] = 1 # Admin

    organization = Organization.find(1)
    expect(organization.managers).to include(User.find(1))

    expect {
      delete :destroy, params: { id: 1,
                                 manager_id: [1] }
    }.to change { OrganizationManager.count }.by(-1)
      .and change { ActionMailer::Base.deliveries.size }.by(1)

    expect(response).to redirect_to(edit_organization_path('org-a', tab: 'managers'))

    mail = ActionMailer::Base.deliveries.last
    email_field = Redmine::VERSION::MAJOR >= 5 ? 'to' : 'bcc'
    expect(mail[email_field].to_s).to include(User.find(1).mail)
    expect(mail[email_field].to_s).to_not include(User.find(3).mail)
    mail.parts.each do |part|
      expect(part.body.raw_source).to include("vient de vous retirer les droits de")
      expect(part.body.raw_source).to_not include("vient de vous donner")
    end

  end

end

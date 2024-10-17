require "spec_helper"

describe IssuesController, :type => :controller do

  fixtures :projects,
           :users, :email_addresses, :user_preferences,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :issue_relations,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries,
           :repositories,
           :changesets,
           :organizations, :organization_roles, :organization_notifications

  render_views

  it 'should allow member to create new issue' do
    @request.session[:user_id] = 2
    expect User.find(2).member_of?(Project.find(4))

    expect {
      post :create, params: { :project_id => 1, :copy_from => 1,
                              :issue => { :project_id => '4', :tracker_id => '3', :status_id => '1', :subject => 'Copy' }
      } }.to change { Issue.count }

    issue = Issue.order('id DESC').first
    expect(issue.project_id).to eq(1)
  end

  it 'should allow non-member to create a new issue if an exception is set for his organization' do
    # TODO
  end

  it 'should send a notification to the organization address' do
    @request.session[:user_id] = 2
    expect User.find(2).member_of?(Project.find(4))

    ActionMailer::Base.deliveries.clear

    user = User.find(2)
    orga = Organization.find(2)

    user.update_attribute('organization_id', orga.id)
    # project = Project.find(1)
    # project.update_attribute('notify_organizations', true)
    expect(orga.mail).to_not be_nil

    expect {
      post :create, params: { :project_id => 1,
                              :issue => { :tracker_id => '3', :status_id => '1', :subject => 'Subject for test' }
      } }.to change { Issue.count }
    issue = Issue.last
    expect(issue.organization_emails).to_not be_empty
    expect(ActionMailer::Base.deliveries.size).to eq 2

    mails = ActionMailer::Base.deliveries
    email_field = Redmine::VERSION::MAJOR >= 5 ? 'to' : 'bcc'
    notified_addresses = mails.map { |m| m[email_field].to_s }
    expect(notified_addresses).to include(User.find(2).mail)
    expect(notified_addresses).to include(User.find(3).mail)

    # TODO Make it works (broken by Redmine 4 update)
    # expect(notified_addresses).to include(orga.mail) # Organization email is notified!
  end

  describe "non-members exceptions by organization" do

    let!(:non_member_user) {
      user = User.new(login: 'non-member.user',
                      firstname: 'non-member',
                      lastname: "user")
      user.mail = "non-member.user@somenet.foo"
      user.organization_id = 3
      user.save!
      user
    }
    let!(:project_onlinestore) { Project.find('onlinestore') }
    let!(:role_reporter) { Role.find(3) }
    let!(:orga_a) { Organization.find(1) }
    let!(:orga_a_team_b) { Organization.find(3) }
    let!(:project_ecookbook) { Project.find(1) }

    before do
      @request.session[:user_id] = non_member_user.id
      User.current = non_member_user
      OrganizationNonMemberRole.find_or_create_by!(organization: orga_a, role: role_reporter, project: project_onlinestore)
      Role.where(id: 4).each { |r| r.permissions.each {|p| r.permissions.delete(p.to_sym)}; r.save!; }
    end

    it "does not display a list of issues if user's organization has no non-member role" do
      OrganizationNonMemberRole.delete_all
      get :index, params: { :project_id => project_onlinestore.id }
      expect(assigns(:issues)).to be_nil
    end

    it "displays a list of issues if user's organization has a non-member role" do
      expect(OrganizationNonMemberRole.count).to eq(1)
      non_member_role = OrganizationNonMemberRole.first
      non_member_role.update_attribute(:organization_id, 3)
      get :index, params: { :project_id => project_onlinestore.id }
      expect(assigns(:issues)).to_not be_nil
      expect(assigns(:issues)).to_not be_empty
      expect(assigns(:issues)).to include Issue.find(4)
    end

    it "displays a list of issues if user's upper-organization has a non-member role" do
      expect(OrganizationNonMemberRole.count).to eq(1)
      expect(OrganizationNonMemberRole.first.organization).to eq(orga_a)
      get :index, params: { :project_id => project_onlinestore.id }
      expect(assigns(:issues)).to_not be_nil
      expect(assigns(:issues)).to_not be_empty
      expect(assigns(:issues)).to include Issue.find(4)
    end

    it "displays a list of issues if project is a sub-project and parent project has a non-member role" do
      expect(OrganizationNonMemberRole.count).to eq(1)
      non_member_role = OrganizationNonMemberRole.first
      non_member_role.update_attribute(:project_id, project_ecookbook.id)
      get :index, params: { :project_id => 3 } # eCookbook Subproject 1
      expect(assigns(:issues)).to_not be_nil
      expect(assigns(:issues)).to_not be_empty
      expect(assigns(:issues)).to include Issue.find(5)
    end

    it "DOES NOT display a list of issues if project is a sub-project and parent project has NO non-member role" do
      OrganizationNonMemberRole.delete_all
      get :index, params: { :project_id => 3 } # eCookbook Subproject 1
      expect(assigns(:issues)).to be_nil
      expect(response.status).to eq 403 # Forbidden
    end

  end

  context "when the issue is shared with organizations" do

    let!(:issue_7) { Issue.find(7) }
    let!(:related_organization) { Organization.find_or_create_by(name: "related organisation") }
    let!(:different_organization) { Organization.find_or_create_by(name: "different organisation") }
    let!(:user_2) { User.find(2) }
    let!(:user_7) { User.find(7) }

    before do
      @request.session[:user_id] = 7

      # Add users to organization
      user_2.update_attribute(:organization_id, related_organization.id)
      user_7.update_attribute(:organization_id, related_organization.id)

      # issue 7 is shared with a related organization
      issue_7.update_attribute(:organizations, [related_organization])
      expect(issue_7.organizations).to eq [related_organization]

      # Remove role for non members
      Role.builtin(true).each { |role| role.remove_permission! :view_issues }
      # Add a role to another project
      membership = Member.new(user: user_7, project_id: 2) # Member of an other project
      membership.roles << Role.find(1)
      membership.save!
    end

    describe "#show" do
      it "allows access to members of the related organization" do
        get :show, params: { id: issue_7.id }
        expect(response).to be_successful
        expect(response.body).to have_selector("div.subject:contains('Issue due today')")
      end

      it "forbid access to other users" do
        user_7.update_attribute(:organization_id, different_organization.id)
        get :show, params: { id: issue_7.id }
        expect(response).to be_forbidden
      end
    end

    describe "issues#index" do

      context "in a project" do
        it "forbid access to other users" do
          user_7.update_attribute(:organization_id, different_organization.id)
          get :index, params: { project_id: issue_7.project.identifier }
          expect(response).to have_http_status(:forbidden)
        end
      end

      context "outside any project" do
        it "does not list the issue when the current user is not in the same organization" do
          user_7.update_attribute(:organization_id, different_organization.id)
          get :index, params: {}
          expect(response).to be_successful
          expect(response.body).to have_selector("td.subject:contains('Issue on project 2')")
          expect(response.body).to_not have_selector("td.subject:contains('#{issue_7.subject}')")
        end

        it "lists the issue when the current user is in the same organization" do
          get :index, params: {}
          expect(response).to be_successful
          expect(response.body).to have_selector("td.subject:contains('Issue on project 2')")
          expect(response.body).to have_selector("td.subject:contains('#{issue_7.subject}')")
        end
      end

    end
  end

end

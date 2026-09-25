require "spec_helper"

describe ProjectsController, :type => :controller do
  fixtures :organizations, :users, :roles, :projects, :members, :member_roles, :organization_roles

  before do
    @request.session[:user_id] = 1
  end

  describe "copy a project" do
    let(:source_project) { Project.find(1) }
    let(:role_manager) { Role.find(1) }
    let(:role_developer) { Role.find(2) }

    it "Copy all organization roles if the option (organizations_roles) is selected" do
      post :copy, :params => {
        :id => source_project.id,
        :project => {
          :name => 'test project',
          :identifier => 'test-project'
        },
        :only => %w(organizations_roles)
      }

      new_pro = Project.last

      expect(new_pro.organization_roles.count).to eq(2)
      expect(new_pro.organization_roles.first.role.id).to eq (role_manager.id)
      expect(new_pro.organization_roles.last.role.id).to eq (role_developer.id)
    end

    it "Should not copy any organization roles if the option (organizations_roles) is not selected" do
      post :copy, :params => {
        :id => source_project.id,
        :project => {
          :name => 'test project',
          :identifier => 'test-project'
        },
        :only => %w(members)
      }

      new_pro = Project.last

      expect(source_project.organization_roles.count).to eq(2)
      expect(new_pro.organization_roles.count).to eq(0)
    end
  end

  describe "settings members tab" do
    render_views

    let(:project) { Project.find(1) }
    let(:organization) { Organization.find(1) }

    before do
      30.times { User.add_to_project(User.generate!(:organization => organization), project) }
    end

    def members_on_page(page, params = {})
      with_settings :per_page_options => '25,50,100' do
        get :settings, :params => {:id => project.identifier, :tab => 'members', :members_page => page}.merge(params)
      end
      Nokogiri::HTML(response.body).css('div#tab-content-members tr.member').map { |row| row['id'] }
    end

    it "paginates members" do
      expect(members_on_page(1).size).to eq(25)
      expect(response.body).to include("settings/members?members_page=2")
      expect(response.body).to_not match(/settings\/members\?[^"]*tab=members/)
    end

    it "lists each member on exactly one page" do
      page1 = members_on_page(1)
      page2 = members_on_page(2)

      expect(page1 & page2).to be_empty
      expect((page1 + page2).size).to eq(project.memberships.count)
    end

    it "repeats the organization row on each page listing its members" do
      members_on_page(1)
      expect(response.body).to include(%(id="organization-#{organization.id}"))
      members_on_page(2)
      expect(response.body).to include(%(id="organization-#{organization.id}"))
    end

    it "keeps the table and the pagination links for an out of range page" do
      expect(members_on_page(99)).to be_empty
      expect(response.body).to include("settings/members?members_page=")
      expect(Nokogiri::HTML(response.body).css('div#tab-content-members .nodata')).to be_empty
    end

    context "with the members per page setting" do
      around do |example|
        with_settings "plugin_redmine_organizations" => {'members_per_page' => '10'} do
          example.run
        end
      end

      it "uses the setting as the default number of members per page" do
        expect(members_on_page(1).size).to eq(10)
      end

      it "keeps a per page value chosen on the members list" do
        expect(members_on_page(1, :per_page => 25).size).to eq(25)
        expect(members_on_page(1).size).to eq(25)
      end

      it "ignores a per page value chosen on another list" do
        @request.session[:per_page] = 25
        expect(members_on_page(1).size).to eq(10)
      end
    end
  end
end
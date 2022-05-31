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
      expect(new_pro.organization_roles.first.role.id  == role_manager.id)
      expect(new_pro.organization_roles.last.role.id  == role_developer.id)
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
end
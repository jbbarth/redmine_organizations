require "spec_helper"

describe Organizations::MembershipsController, :type => :controller do

  render_views

  fixtures :organizations, :organization_managers, :users,
           :organization_team_leaders, :members, :member_roles, :roles, :projects

  describe 'Admin actions' do
    before do
      @request.session[:user_id] = 1
    end

    it "should delete all members from an organization" do
      user1 = User.find(2)
      user1.organization = Organization.find(1)
      user1.save
      user2 = User.find(3)
      user2.organization = Organization.find(1)
      user2.save
      expect do
        delete :destroy_organization, :params => {
          :project_id => 1,
          :id => 1
        }
      end.to change { Member.count }.by(-2)
    end

    it "should delete all members from an organization except lock one" do

      user1 = User.find(8)
      user1.organization = Organization.find(1)
      user1.save
      user2 = User.find(2)
      user2.organization = Organization.find(1)
      user2.save

      expect do
        delete :destroy_organization, :params => {
          :project_id => 5,
          :id => 1
        }
      end.to change { Member.count }.by(-1)
    end
  end
end
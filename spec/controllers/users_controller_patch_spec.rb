require "spec_helper"

describe UsersController, type: :controller do

  describe 'method_update_memberships_according_to_new_orga' do
    fixtures :organizations, :users, :roles, :projects, :members, :member_roles,
             :organization_managers, :organization_team_leaders

    before do
      @request.session[:user_id] = 1
    end

    it "should not modify existing roles per projects if params == keep" do
      user = User.find(2)
      previous_memberships = user.memberships
      previous_organization = user.organization
      put :update, params: {:id => 2,
                            :user => {:organization_id => '2', :orga_update_method => 'keep'}}
      user = user.reload
      assert_equal 2, user.organization_id
      assert_equal previous_memberships, user.memberships
      expect(user.organization).to_not eq previous_organization
    end

    it "should destroy all existing roles per projects if params == remove" do
      user = User.find(2)
      membership = Member.new(user_id: user.id, project_id: 2)
      membership.roles = [Role.first]
      user.memberships << membership
      previous_memberships = user.memberships
      previous_organization = user.organization
      put :update, params: {:id => 2,
                            :user => {:organization_id => '2', :orga_update_method => 'remove'}}
      user = user.reload
      expect(user.memberships).to_not eq previous_memberships
      expect(user.organization).to_not eq previous_organization
      expect(user.organization_id).to eq 2
      expect(user.memberships).to eq []
    end

    it "should copy all roles from specified user if params == replace" do
      user = User.find(2)
      membership = Member.new(user_id: user.id, project_id: 2)
      membership.roles = [Role.first]
      user.memberships << membership
      previous_memberships = user.memberships
      previous_organization = user.organization
      put :update, params: {:id => 2,
                            :user => {:organization_id => '2', :orga_update_method => 'replace'},
                            :copy_user => '3'}
      user = user.reload
      expect(user.memberships).to_not eq previous_memberships
      expect(user.organization).to_not eq previous_organization
      expect(user.organization_id).to eq 2
      expect(user.memberships.map(&:project)).to eq User.find(3).memberships.map(&:project)
    end
    # In the case of removing the property(disabled) from the option( Duplicate roles and projects) by the page inspector
    it "Should not show any error if params == replace and copy_user is nil" do
      put :update, params: {:id => 2,
                            :user => {:organization_id => '2',
                            :orga_update_method => 'replace'}}

      expect(response).to have_http_status(:redirect)
    end

  end
end

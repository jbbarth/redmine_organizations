require "spec_helper"

describe Organizations::MembershipsController, :type => :controller do

  render_views

  fixtures :organizations, :organization_managers, :users,
           :organization_team_leaders, :members, :member_roles, :roles, :projects

  describe 'Admin actions' do
    let!(:journal_detail_count_before_delation) { JournalDetail.count } if Redmine::Plugin.installed?(:redmine_admin_activity)

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

      if Redmine::Plugin.installed?(:redmine_admin_activity)
        journal_detail_count_after_delation = JournalDetail.count

        expect(journal_detail_count_after_delation).to eq(journal_detail_count_before_delation + 4)

        last_journals_for_delection_of_member = JournalDetail.last(4)
        user1_journal = last_journals_for_delection_of_member[0]
        user2_journal = last_journals_for_delection_of_member[2]

        user1_name = JSON.parse(user1_journal.old_value)["name"]
        user2_name = JSON.parse(user2_journal.old_value)["name"]

        pro_key_value = Redmine::Plugin.installed?(:redmine_limited_visibility) ? 'member_roles_and_functions' : 'member_with_roles'

        expect(user1_journal).to have_attributes(:prop_key => pro_key_value)
        expect(user2_journal).to have_attributes(:prop_key => pro_key_value)
        expect(user1_name).to eq(user1.name).or eq(user2.name)
        expect(user2_name).to eq(user1.name).or eq(user2.name)
      end
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

      if Redmine::Plugin.installed?(:redmine_admin_activity)
        journal_detail_count_after_delation = JournalDetail.count

        expect(journal_detail_count_after_delation).to eq(journal_detail_count_before_delation + 2)

        last_journal_for_delection_of_member = JournalDetail.last(2)[0]
        user_name = JSON.parse(last_journal_for_delection_of_member.old_value)["name"]

        pro_key_value = Redmine::Plugin.installed?(:redmine_limited_visibility) ? 'member_roles_and_functions' : 'member_with_roles'

        expect(last_journal_for_delection_of_member).to have_attributes(:prop_key => pro_key_value)
        expect(user_name).to eq(user2.name)
      end
    end

    if Redmine::Plugin.installed?(:redmine_admin_activity)
      it "add logs on JournalDetail when change non_member roles" do
        expect do
          patch :update_group_non_member_roles, :params => {
            :project_id => 5,
            :membership => { :role_ids => ["2", "3"] },
            :group_id => 12
          }
        end.to change { JournalDetail.count }.by (1)

        expect(JournalDetail.last.property).to eq("members")
        expect(JournalDetail.last.prop_key).to eq("member_roles_and_functions")
      end
    end
  end
end

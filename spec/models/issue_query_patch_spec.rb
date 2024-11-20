require "rails_helper"

describe "IssueQueryPatch" do
  fixtures :organizations, :users, :roles, :projects, :members, :trackers

  context "filter issues with updated_by_organization" do
    before do
      @org = Organization.create(:name => "Team C")
      @user = User.generate!
      expect(@user).to be_present
      @user.update_attribute(:organization_id, @org.id)
      User.current = User.anonymous
    end

    def find_issues_ids_with_query(query)
      Issue.joins(:status, :tracker, :project, :priority).where(
        query.statement
      ).order(:id).pluck(:id)
    end

    it "Should have updated_by_organization in available_filters" do
      query = IssueQuery.new(:name => '_')
      expect(query.available_filters.keys).to include('updated_by_organization')
    end

    it "operator equal = , one organization" do
      Journal.create!(:user_id => @user.id, :journalized => Issue.find(2), :notes => 'Notes')
      Journal.create!(:user_id => @user.id, :journalized => Issue.find(3), :notes => 'Notes')
      Journal.create!(:user_id => 2, :journalized => Issue.find(4), :notes => 'Notes')

      query = IssueQuery.new(:name => '_')
      filter_name = "updated_by_organization"

      query.filters = { filter_name => { :operator => '=', :values => [@org.id.to_s] } }

      expect(find_issues_ids_with_query(query)).to include(2, 3)
    end

    it "operator equal ! , one organization" do
      Journal.create!(:user_id => @user.id, :journalized => Issue.find(2), :notes => 'Notes')
      Journal.create!(:user_id => @user.id, :journalized => Issue.find(3), :notes => 'Notes')
      Journal.create!(:user_id => 2, :journalized => Issue.find(4), :notes => 'Notes')

      query = IssueQuery.new(:name => '_')
      filter_name = "updated_by_organization"
      query.filters = { filter_name => { :operator => '!', :values => [@org.id.to_s] } }

      expect(find_issues_ids_with_query(query)).to_not include(2, 3)
    end

    it "operator equal = , multi organizations" do
      user_test = User.find(2)
      org_test = Organization.find(2)
      user_test.update_attribute(:organization_id, org_test.id)

      Journal.create!(:user_id => @user.id, :journalized => Issue.find(2), :notes => 'Notes')
      Journal.create!(:user_id => @user.id, :journalized => Issue.find(3), :notes => 'Notes')
      Journal.create!(:user_id => user_test.id, :journalized => Issue.find(4), :notes => 'Notes')

      query = IssueQuery.new(:name => '_')
      filter_name = "updated_by_organization"
      query.filters = { filter_name => { :operator => '=', :values => [@org.id.to_s, org_test.id.to_s] } }

      expect(find_issues_ids_with_query(query)).to include(2, 3, 4)
    end

    it "operator equal ! , multi organizations" do
      user_test = User.find(2)
      org_test = Organization.find(2)
      user_test.update_attribute(:organization_id, org_test.id)

      Journal.create!(:user_id => @user.id, :journalized => Issue.find(2), :notes => 'Notes')
      Journal.create!(:user_id => @user.id, :journalized => Issue.find(3), :notes => 'Notes')
      Journal.create!(:user_id => user_test.id, :journalized => Issue.find(4), :notes => 'Notes')

      query = IssueQuery.new(:name => '_')
      filter_name = "updated_by_organization"
      query.filters = { filter_name => { :operator => '=', :values => [@org.id.to_s, org_test.id.to_s] } }

      expect(find_issues_ids_with_query(query)).to_not include([2, 3, 4])
    end

    it "ignores private notes that are not visible" do
      Journal.create!(:user_id => @user.id, :journalized => Issue.find(2), :notes => 'Notes', :private_notes => true)
      Journal.create!(:user_id => @user.id, :journalized => Issue.find(3), :notes => 'Notes')

      query = IssueQuery.new(:name => '_')
      filter_name = "updated_by_organization"

      User.current = @user
      query.filters = { filter_name => { :operator => '=', :values => [@org.id.to_s] } }
      expect(find_issues_ids_with_query(query)).to eq([2, 3])

      User.current = User.anonymous
      query.filters = { filter_name => { :operator => '=', :values => [@org.id.to_s] } }
      expect(find_issues_ids_with_query(query)).to eq([3])
    end
  end

  context "filter issues by related organizations" do
    it "adds a relate organization column" do
      expect(IssueQuery.available_columns.find { |column| column.name == :related_organizations }).to be_present
    end
  end
end

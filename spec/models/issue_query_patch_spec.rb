require "spec_helper"

describe "IssueQueryPatch" do
  fixtures :organizations, :users, :roles, :projects, :members, :trackers

  context "should filter issues with updated_by_organization" do
    before do
      @org = Organization.create(:name => "Team C")
      @user = User.generate!
      @user.update_attribute(:organization_id, @org.id)
    end

    def find_issues_with_query(query)
      Issue.joins(:status, :tracker, :project, :priority).where(
        query.statement
      ).to_a
    end

    it "Should have updated_by_organization in available_filters" do
      query = IssueQuery.new(:name => '_')
      expect(query.available_filters.keys).to include('updated_by_organization')
    end

    it "operator equal =, one organization" do
      Journal.create!(:user_id => @user.id, :journalized => Issue.find(2), :notes => 'Notes')
      Journal.create!(:user_id => @user.id, :journalized => Issue.find(3), :notes => 'Notes')
      Journal.create!(:user_id => 2, :journalized => Issue.find(4), :notes => 'Notes')

      query = IssueQuery.new(:name => '_')
      filter_name = "updated_by_organization"
      query.filters = { filter_name => {:operator => '=', :values => [@org.id.to_s] }}

      expect(find_issues_with_query(query).map(&:id).sort).to include([2, 3])
    end

    it "operator equal ! , one organization" do
      Journal.create!(:user_id => @user.id, :journalized => Issue.find(2), :notes => 'Notes')
      Journal.create!(:user_id => @user.id, :journalized => Issue.find(3), :notes => 'Notes')
      Journal.create!(:user_id => 2, :journalized => Issue.find(4), :notes => 'Notes')

      query = IssueQuery.new(:name => '_')
      filter_name = "updated_by_organization"
      query.filters = { filter_name => {:operator => '!', :values => [@org.id.to_s] }}

      expect(find_issues_with_query(query).map(&:id).sort).to_not include([2, 3])
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
      query.filters = { filter_name => {:operator => '=', :values => [@org.id.to_s, org_test.id.to_s] }}

      expect(find_issues_with_query(query).map(&:id).sort).to include(2, 3, 4)
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
      query.filters = { filter_name => {:operator => '=', :values => [@org.id.to_s, org_test.id.to_s] }}

      expect(find_issues_with_query(query).map(&:id).sort).to_not include([2, 3, 4])
    end

    it "Should ignore private notes that are not visible" do
      Journal.create!(:user_id => @user.id, :journalized => Issue.find(2), :notes => 'Notes', :private_notes => true)
      Journal.create!(:user_id => @user.id, :journalized => Issue.find(3), :notes => 'Notes')

      query = IssueQuery.new(:name => '_')
      filter_name = "updated_by_organization"
      query.filters = {filter_name => {:operator => '=', :values => [@org.id.to_s]}}

      expect(find_issues_with_query(query).map(&:id).sort).to eq([2, 3])

      User.current =  User.anonymous
      query.filters = {filter_name => {:operator => '=', :values => [@org.id.to_s]}}

      expect(find_issues_with_query(query).map(&:id).sort).to eq([3])
    end
  end
end

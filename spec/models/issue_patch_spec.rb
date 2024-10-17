require "spec_helper"

RSpec.describe Issue, :type => :model do

  fixtures :organizations, :users, :roles, :projects, :members, :member_roles,
           :issues_organizations, :issues, :trackers, :issue_statuses, :enabled_modules,
           :enumerations

  context "#organization_emails" do
    before do
      # no user has an org at first, so just play with one
      @orga = Organization.find(1)
      @user = User.find(1)
      @user.update_attribute(:organization_id, @orga.id)
    end

    it "should Issue#organization_emails" do
      # just to be sure our patch is applied
      expect(Issue.instance_methods).to include(:organization_emails)
    end

    it "should be empty when a project has no org" do
      # user(1) is not on project(3)
      expect(@user.member_of? Project.find(3)).to be_falsey, "user should not be member of project 3 for the next assertion"
      expect(Issue.new(:project_id => 3).organization_emails).to eq []
    end

    it "should be empty when a project has an org but org no mail" do
      @orga.update_attribute(:mail, "")
      expect(@user.member_of? Project.find(5)).to be_truthy, "user should be member of project 5 for the next assertion"
      expect(Issue.new(:project_id => 5).organization_emails).to eq []
    end

    it "should NOT contain mail of organizations for the project if the organization don't want to be notified" do
      @orga.update_attribute(:mail, "org@example.net")
      @orga.notified_projects = @orga.notified_projects - [Project.find(5)]
      expect(@user.member_of? Project.find(5)).to be_truthy, "user should be member of project 5 for the next assertion"
      expect(Issue.new(:project_id => 5).organization_emails).to_not include "org@example.net"
    end

    it "should contain mail of organizations for the project if settings are all true" do
      @orga.update_attribute(:mail, "org@example.net")
      @orga.notified_projects = @orga.notified_projects | [Project.find(5)]
      expect(@user.member_of? Project.find(5)).to be_truthy, "user should be member of project 5 for the next assertion"
      expect(Issue.new(:project_id => 5).organization_emails).to eq ["org@example.net"]
    end
  end

  context "issue is shared with related organizations" do

    let!(:issue_7) { Issue.find(7) }
    let!(:user_2) { User.find(2) }
    let!(:user_7) { User.find(7) }
    let!(:user_8) { User.find(8) }
    let!(:user_9) { User.find(9) }
    let!(:other_related_organization) { Organization.find_or_create_by(name: "other related organisation") }
    let!(:different_organization) { Organization.find_or_create_by(name: "different organisation") }
    let!(:related_organization) { Organization.find_or_create_by(name: "related organisation") }

    before do
      user_2.update_attribute(:organization_id, related_organization.id)
      user_7.update_attribute(:organization_id, related_organization.id)
      user_7.update_attribute(:mail_notification, 'all')
      user_8.update_attribute(:organization_id, other_related_organization.id) # let's say user8 is a member of another related organization
      user_9.update_attribute(:organization_id, different_organization.id) # let's say user9 is a member of a different unrelated organization

      # issue 7 is shared with related_organization
      issue_7.update_attribute(:organizations, [related_organization])

      # related_organization has a parent organization
      related_organization.update_attribute(:parent_id, other_related_organization.id)

      # Remove role for non members
      Role.builtin(true).each { |role| role.remove_permission! :view_issues }
    end

    it "lists organizations of an issue" do
      issue = Issue.find(1)
      expect(issue.organizations).to eq [Organization.find(1)]
    end

    describe "related_organizations_members method" do
      it "returns nobody if the issue has no related organization" do
        issue_7.update_attribute(:organizations, [])
        expect(issue_7.related_organizations_members).to eq []
      end
    end

    context "An issue may have multiple organizations" do

      it "returns an array with organization users if the issue has a related organization" do
        issue_7.update_attribute(:organizations, [related_organization])
        expect(issue_7.related_organizations_members).to eq [user_2, user_7]
      end

      it "returns an array with the organizations users if the issue has several related organizations" do
        issue_7.update_attribute(:organizations, [related_organization, other_related_organization])
        expect(related_organization.users).to include(user_2)
        expect(related_organization.users).to include(user_7)
        expect(related_organization.users).to_not include(user_8)
        expect(issue_7.related_organizations_members.sort).to eq [user_8, user_2, user_7].sort
        expect(issue_7.related_organizations_members.sort).to_not include(user_9)
      end

      it "returns an array with the organizations users if the issue has NOT related organizations" do
        issue_7.update_attribute(:organizations, [related_organization, other_related_organization, different_organization])
        expect(related_organization.users).to include(user_2)
        expect(related_organization.users).to include(user_7)
        expect(related_organization.users).to_not include(user_8)
        expect(related_organization.users).to_not include(user_9)
        expect(issue_7.related_organizations_members.sort_by(&:id)).to eq [user_9, user_8, user_2, user_7].sort_by(&:id)
      end

      describe "visible?" do
        it "does not allow access when we are not member of a related organization" do
          issue_7.update_attribute(:organizations, [])
          expect(issue_7.visible?(user_7)).to be false
          expect(issue_7.visible?(user_8)).to be false
        end

        it "allows a user to see an issue if he is member of a related organization" do
          issue_7.update_attribute(:organizations, [related_organization])
          expect(issue_7.visible?(user_7)).to be true
          expect(issue_7.visible?(user_8)).to be false
        end
      end

      describe "notified_users" do
        it "notifies users who are members of related organizations" do
          notified = issue_7.notified_as_member_of_related_organizations
          expect(notified).to_not be_nil
          expect(notified).to_not include User.anonymous
          expect(notified).to include user_7 # member of related organization
          expect(notified).to_not include user_8 # not member
        end

        it "notifies all member of related organizations" do
          notified_users = issue_7.notified_users
          expect(notified_users).to_not be_nil
          expect(notified_users).to_not include User.anonymous
          expect(notified_users).to include user_2 # author
          expect(notified_users).to include user_7 # member of related organization
          expect(notified_users).to_not include user_8 # not member
        end

      end
    end
  end
end

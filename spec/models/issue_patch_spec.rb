require "spec_helper"

describe "IssuePatch" do
  fixtures :organizations, :users, :roles, :projects, :members, :member_roles

  context "#organization_emails" do
    before do
      #no user has an org at first, so just play with one
      @orga = Organization.find(1)
      @user = User.find(1)
      @user.update_attribute(:organization_id, @orga.id)
    end

    it "should Issue#organization_emails" do
      # just to be sure our patch is applied
      expect(Issue.instance_methods).to include(:organization_emails)
    end

    it "should be empty when a project has no org" do
      #user(1) is not on project(3)
      expect(@user.member_of? Project.find(3) ).to be_falsey, "user should not be member of project 3 for the next assertion"
      expect(Issue.new(:project_id => 3).organization_emails).to eq []
    end

    it "should be empty when a project has an org but org no mail" do
      @orga.update_attribute(:mail, "")
      expect( @user.member_of? Project.find(5) ).to be_truthy, "user should be member of project 5 for the next assertion"
      expect(Issue.new(:project_id => 5).organization_emails).to eq []
    end

    it "should NOT contain mail of organizations for the project if the organization don't want to be notified" do
      @orga.update_attribute(:mail, "org@example.net")
      @orga.notified_projects = @orga.notified_projects - [Project.find(5)]
      expect(@user.member_of? Project.find(5) ).to be_truthy, "user should be member of project 5 for the next assertion"
      expect(Issue.new(:project_id => 5).organization_emails).to_not include "org@example.net"
    end

    it "should contain mail of organizations for the project if settings are all true" do
      @orga.update_attribute(:mail, "org@example.net")
      @orga.notified_projects = @orga.notified_projects | [Project.find(5)]
      expect(@user.member_of? Project.find(5) ).to be_truthy, "user should be member of project 5 for the next assertion"
      expect(Issue.new(:project_id => 5).organization_emails).to eq ["org@example.net"]
    end
  end
end

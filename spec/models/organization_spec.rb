require "spec_helper"

describe "Organization" do
  fixtures :organizations, :users, :roles, :projects, :members, :member_roles, :organization_managers
  fixtures :organization_functions if Redmine::Plugin.installed?(:redmine_limited_visibility)

  it "should test_organization_tree_sorting" do
    o = Organization.create(:name => "Team C", :parent_id => 1)
    expect(o.left_sibling.name).to eq "Team B"
    o.update_attributes(:name => "Team 0")
    expect(o.right_sibling.name).to eq "Team A"
    expect(o.left_sibling).to be_nil
    o.update_attributes(:name => "A new org", :parent_id => nil)
    expect(o.right_sibling.name).to eq "Org A"
  end

  it "should Organization#fullname" do
    expect(Organization.find(1).fullname).to eq "Org A"
    expect(Organization.find(2).fullname).to eq "Org A/Team A"
  end

  it "should Organization#direction" do
    assert Organization.find(1).direction?
    assert ! Organization.find(2).direction?
    expect(Organization.find(2).direction_organization.id).to eq 1
  end

  it "should organization_validations" do
    already_taken_orga = Organization.new(name: "Team A", parent_id: 1) #orga with same name and same parent already exists
    assert !already_taken_orga.valid?
    assert_match /already been taken/, already_taken_orga.errors[:name].first

    same_name_orga = Organization.new(name: "Team A", parent_id: 3) #same name but different parent : OK
    assert same_name_orga.valid?
  end

  it "should test organization_tree class method" do
    result = []
    Organization.organization_tree(Organization.all) do |organization, level|
      result << {level => organization.name}
    end
    assert_equal result, [{0=>"Org A"}, {1=>"Team A"}, {1=>"Team B"}]
  end

  it "should test Organization#managers" do
    expect(Organization.find(1).managers).to eq [User.find(1)]
  end

  it "should test Organization#inherited_managers" do
    expect(Organization.find(2).managers).to eq [User.find(2)]
    expect(Organization.find(2).inherited_managers).to eq [User.find(1)]
  end

  it "should test Organization#all_managers" do
    expect(Organization.find(2).all_managers).to eq [User.find(2), User.find(1)]
  end

  describe "Update the relationship tables in case of cascade deleting" do
    let(:organization) { Organization.find(1) }

    if Redmine::Plugin.installed?(:redmine_limited_visibility)
      it "Update OrganizationFunction table, when deleting a organization" do
        expect do
          organization.destroy
        end.to change { OrganizationFunction.count }.by(-1)
      end
    end

    it "Update OrganizationRole table, when deleting a organization" do
      expect do
        organization.destroy
      end.to change { OrganizationRole.count }.by(-1)
      .and change { OrganizationManager.count }.by(-1)
      .and change { OrganizationTeamLeader.count }.by(-1)
    end

    it "when deleting a project" do
      project = Project.find(1)
      expect do
        project.destroy
      end.to change { OrganizationRole.count }.by(-2)
    end

    it "when deleting a role" do
      role_test = Role.create!(:name => 'Test')
      OrganizationRole.create(project_id: 1, role_id: role_test.id, organization_id: organization.id)
      expect do
        role_test.destroy
      end.to change { OrganizationRole.count }.by(-1)
    end
  end

  describe "organization synchronization with LDAP" do
    it "creates new organization from ldap departmentnumber" do
      expect do
        Organization.find_or_create_from_ldap(departmentnumber: "DIR/SUBDIR/MAIN/TEAM", description: "Team A working with Main Group")
      end.to change { Organization.count }.by(4)
      expect(Organization.last.description).to eq "Team A working with Main Group"
    end

    it "does not change existing organization" do
      expect do
        Organization.find_or_create_from_ldap(departmentnumber: "Org A/Team A")
      end.to_not change { Organization.count }
    end
  end
end

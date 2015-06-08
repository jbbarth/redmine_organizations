require "spec_helper"

describe "Organization" do
  fixtures :organizations, :users, :roles, :projects, :members, :member_roles

  it "should test_organization_tree_sorting" do
    o = Organization.create(:name => "Team C", :parent_id => 1)
    expect(o.left_sibling.name).to eq "Team B"
    o.update_attributes(:name => "Team 0")
    expect(o.right_sibling.name).to eq "Team A"
    assert_nil o.left_sibling
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

end

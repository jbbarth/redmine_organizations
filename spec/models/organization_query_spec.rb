require "spec_helper"

describe OrganizationQuery do
  fixtures :organizations, :organization_managers, :organization_team_leaders, :users

  def find_ids_with_filter(field, operator, values)
    query = OrganizationQuery.new(name: '_')
    query.add_filter(field, operator, values)
    query.results_scope.pluck(:id)
  end

  it "returns organizations in tree order by default" do
    query = OrganizationQuery.new(name: '_')
    expect(query.tree_order?).to be true
    expect(query.results_scope.pluck(:id)).to eq [1, 2, 3]
  end

  it "is no longer in tree order when sorted" do
    query = OrganizationQuery.new(name: '_', sort_criteria: [['name', 'desc']])
    expect(query.tree_order?).to be false
    expect(query.results_scope.pluck(:id)).to eq [3, 2, 1]
  end

  it "sorts on the parent full name" do
    query = OrganizationQuery.new(name: '_', sort_criteria: [['parent_fullname', 'asc'], ['name', 'desc']])
    # NULL ordering depends on the database
    expect(query.results_scope.pluck(:id) - [1]).to eq [3, 2]
  end

  it "groups by direction" do
    query = OrganizationQuery.new(name: '_', group_by: 'direction')
    expect(query.tree_order?).to be false
    expect(query.result_count_by_group.transform_keys { |k| ActiveModel::Type::Boolean.new.cast(k) }).to eq(true => 1, false => 2)
    expect(query.results_scope.map(&:direction?)).to eq [false, false, true]
  end

  it "displays a NULL boolean as false" do
    column = OrganizationQuery.new.available_columns.detect { |c| c.name == :direction }
    expect(Organization.find(2).direction).to be_nil
    expect(column.value_object(Organization.find(2))).to be false
  end

  it "filters on the full name" do
    expect(find_ids_with_filter('name', '~', ['org a/team'])).to contain_exactly(2, 3)
  end

  it "filters on direction, a NULL value being false" do
    expect(find_ids_with_filter('direction', '=', ['1'])).to eq [1]
    expect(find_ids_with_filter('direction', '=', ['0'])).to contain_exactly(2, 3)
    expect(find_ids_with_filter('direction', '!', ['1'])).to contain_exactly(2, 3)
  end

  it "filters on the parent organization" do
    expect(find_ids_with_filter('parent_id', '=', ['1'])).to contain_exactly(2, 3)
    expect(find_ids_with_filter('parent_id', '!*', [''])).to eq [1]
  end

  it "filters on managers" do
    expect(find_ids_with_filter('manager_id', '=', ['2'])).to eq [2]
    expect(find_ids_with_filter('manager_id', '*', [''])).to contain_exactly(1, 2)
    expect(find_ids_with_filter('manager_id', '!*', [''])).to eq [3]
  end

  it "filters on team leaders" do
    expect(find_ids_with_filter('team_leader_id', '=', ['1'])).to eq [1]
    expect(find_ids_with_filter('team_leader_id', '!', ['1'])).to contain_exactly(2, 3)
  end

  it "is visible to logged users when public" do
    query = OrganizationQuery.create!(name: 'Public', visibility: Query::VISIBILITY_PUBLIC, user_id: 1)
    expect(OrganizationQuery.visible(User.find(3))).to include(query)
    expect(query.visible?(User.find(3))).to be true
  end

  it "is visible to its author only when private" do
    query = OrganizationQuery.create!(name: 'Private', visibility: Query::VISIBILITY_PRIVATE, user_id: 2)
    expect(OrganizationQuery.visible(User.find(2))).to include(query)
    expect(OrganizationQuery.visible(User.find(3))).not_to include(query)
  end

  it "cannot belong to a project" do
    query = OrganizationQuery.new(name: 'Project', project_id: 1)
    expect(query).not_to be_valid
  end
end

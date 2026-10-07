require "spec_helper"

describe QueriesController, :type => :controller do
  fixtures :organizations, :users, :roles, :members, :member_roles, :projects

  before do
    @request.session[:user_id] = 1
  end

  it "redirects to the organizations list after saving an organization query" do
    expect {
      post :create, params: {type: 'OrganizationQuery', query: {name: 'Directions', visibility: '2'},
                             f: ['direction', ''], op: {direction: '='}, v: {direction: ['1']}}
    }.to change { OrganizationQuery.count }.by(1)

    query = OrganizationQuery.last
    expect(response).to redirect_to(organizations_path(query_id: query.id))
    expect(query.filters).to eq('direction' => {operator: '=', values: ['1']})
  end

  it "returns remote filter values to a non admin user" do
    @request.session[:user_id] = 3
    get :filter, params: {type: 'OrganizationQuery', name: 'parent_id'}
    expect(response).to be_successful
    expect(response.parsed_body).to include(['Org A', '1'])
  end
end

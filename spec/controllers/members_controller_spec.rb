require "spec_helper"

describe MembersController, :type => :controller do
  render_views

  fixtures :organizations, :users, :roles, :projects, :members, :member_roles, :organization_roles

  before do
    @request.session[:user_id] = 1
  end

  it "keeps the current members page in the edit form action" do
    get :edit, :params => {:id => 2, :members_page => 2}, :xhr => true

    expect(response).to be_successful
    expect(response.body).to match(%r{/memberships/2\?members_page=2})
  end

  it "keeps the current members page in the pagination links after an update" do
    26.times { User.add_to_project(User.generate!, Project.find(1)) }

    with_settings :per_page_options => '25,50,100' do
      put :update, :params => {:id => 2, :members_page => 2, :membership => {:role_ids => [1]}}, :xhr => true
    end

    expect(response).to be_successful
    expect(response.body).to match(%r{settings/members\?members_page=1})
  end
end

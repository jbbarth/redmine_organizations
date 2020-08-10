require "spec_helper"

describe MyController, :type => :controller do

  fixtures :users, :organizations, :organization_managers

  let(:not_admin_user) { User.find(2) }
  let(:organization_2) {Organization.find(2)}

  before(:each) do
    not_admin_user.update_attribute('organization_id', 2)
  end

  it "prevents attributes update when current-user is not authorized" do
    @request.session[:user_id] = not_admin_user.id
    expect(not_admin_user.organization).to eq organization_2

    put :account, params: {'user': {'organization_id': '1'}}

    expect(not_admin_user.reload.organization).to eq organization_2 # Organization should not be updated
  end

end

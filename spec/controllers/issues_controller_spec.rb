require "spec_helper"
require "active_support/testing/assertions"

describe IssuesController, :type => :controller do

  fixtures :organizations

  render_views

  it 'should allow member to create new issue' do
    @request.session[:user_id] = 2
    expect User.find(2).member_of?(Project.find(4))
    expect {
      post :create, :project_id => 1, :copy_from => 1,
           :issue => {:project_id => '4', :tracker_id => '3', :status_id => '1', :subject => 'Copy'}
    }.to change {Issue.count}
    issue = Issue.order('id DESC').first
    expect(issue.project_id).to eq(1)
  end

  it 'should allow non-member to create a new issue if an exception is set for his organization' do
    # TODO
  end

end

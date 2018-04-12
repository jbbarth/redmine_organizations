require "spec_helper"

describe IssuesController, :type => :controller do

  fixtures :projects,
           :users, :email_addresses, :user_preferences,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :issue_relations,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries,
           :repositories,
           :changesets,
           :organizations, :organization_roles

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

  it 'should send a notification to the organization address' do
    @request.session[:user_id] = 2
    expect User.find(2).member_of?(Project.find(4))

    ActionMailer::Base.deliveries.clear

    user = User.find(2)
    project = Project.find(1)
    orga = Organization.find(2)

    user.update_attribute('organization_id', orga.id)
    project.update_attribute('notify_organizations', true)
    
    expect(orga.mail).to_not be_nil

    expect {
      post :create, :project_id => 1,
           :issue => {:tracker_id => '3', :status_id => '1', :subject => 'Subject for test'}
    }.to change {Issue.count}
    issue = Issue.last
    expect(issue.organization_emails).to_not be_empty
    expect(ActionMailer::Base.deliveries.size).to eq 1

    mail = ActionMailer::Base.deliveries.last
    expect(mail['bcc'].to_s).to include(User.find(2).mail)
    expect(mail['bcc'].to_s).to include(User.find(3).mail)

    expect(mail['bcc'].to_s).to include(orga.mail) # Organization email is notified!
  end

end

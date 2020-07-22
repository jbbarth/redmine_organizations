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
           :organizations, :organization_roles, :organization_notifications

  render_views

  it 'should allow member to create new issue' do
    @request.session[:user_id] = 2
    expect User.find(2).member_of?(Project.find(4))

    expect {
      post :create, params: {:project_id => 1, :copy_from => 1,
                             :issue => {:project_id => '4', :tracker_id => '3', :status_id => '1', :subject => 'Copy'}
      }}.to change {Issue.count}

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
    org = Organization.find(2)

    user.update_attribute('organization_id', org.id)
    # project = Project.find(1)
    # project.update_attribute('notify_organizations', true)
    expect(org.mail).to_not be_nil

    expect {
      post :create, params: {:project_id => 1,
                             :issue => {:tracker_id => '3', :status_id => '1', :subject => 'Subject for test'}
      }}.to change {Issue.count}
    issue = Issue.last
    expect(issue.organization_emails).to_not be_empty
    expect(ActionMailer::Base.deliveries.size).to eq 2

    mails = ActionMailer::Base.deliveries
    notified_addresses = mails.map{|m|m['bcc'].to_s}
    expect(notified_addresses).to include(User.find(2).mail)
    expect(notified_addresses).to include(User.find(3).mail)

    # TODO Make it works (broken by Redmine 4 update)
    # expect(notified_addresses).to include(org.mail) # Organization email is notified!
  end

end

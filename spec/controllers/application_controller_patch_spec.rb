require "spec_helper"

describe ProjectsController, :type => :controller do
  fixtures :organizations, :users, :email_addresses, :roles, :projects, :members, :member_roles,
           :enabled_modules, :trackers, :projects_trackers

  let(:user) { User.find(4) } # member of no project
  let(:project) { Project.find(5) } # private subproject of project 1

  before do
    user.update_column(:organization_id, 2)
    @request.session[:user_id] = user.id
  end

  def grant_organization_role(permissions, organization_id: 1)
    role = Role.generate!(permissions: permissions)
    # Granted on the parent project
    OrganizationNonMemberRole.create!(organization_id: organization_id, role: role, project_id: 1)
  end

  it "denies actions not allowed by the role of the organization exception" do
    grant_organization_role([:view_project, :view_issues])

    patch :update, params: { id: project.id, project: { name: 'Renamed' } }

    expect(response).to have_http_status(:forbidden)
    expect(project.reload.name).not_to eq 'Renamed'
  end

  it "allows actions granted by the role of the organization exception" do
    grant_organization_role([:view_project, :edit_project])

    patch :update, params: { id: project.id, project: { name: 'Renamed' } }

    expect(response).to redirect_to(settings_project_path(project))
    expect(project.reload.name).to eq 'Renamed'
  end

  it "denies actions to users of organizations without exception" do
    user.update_column(:organization_id, 3)
    grant_organization_role([:view_project, :edit_project], organization_id: 2)

    patch :update, params: { id: project.id, project: { name: 'Renamed' } }

    expect(response).to have_http_status(:forbidden)
  end
end

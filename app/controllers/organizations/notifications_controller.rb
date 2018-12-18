class Organizations::NotificationsController < ApplicationController

  before_action :find_organization_by_id
  before_action :require_admin_or_manager

  def update
    @projects = Project.active.where(id: params[:projects])
    @organization.notified_projects = @projects
    @organization.touch
    respond_to do |format|
      format.html { redirect_to edit_organization_path(@organization, :tab => 'memberships') }
      format.js
    end
  end

end

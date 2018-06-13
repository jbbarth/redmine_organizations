class Organizations::ManagersController < ApplicationController

  before_filter :require_admin

  def update
    @organization = Organization.find(params[:id])
    @managers = User.active.where(id: params[:manager_ids])
    @organization.managers = @managers
    @organization.touch
    respond_to do |format|
      format.html { redirect_to edit_organization_path(@organization, :tab => 'users') }
      format.js
    end
  end

end

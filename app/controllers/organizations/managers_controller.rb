class Organizations::ManagersController < ApplicationController

  before_action :find_organization_by_id
  before_action :require_admin_or_manager

  def create
    @managers = User.active.where(id: params[:manager_ids])
    @organization.managers << @managers
    respond_to do |format|
      format.html { redirect_to edit_organization_path(@organization.identifier, tab: 'managers') }
      format.js { render :add_managers }
    end
  end

  def destroy
    user = User.find(params[:manager_id])
    @organization.managers.delete(user)

    if params[:page].present? && params[:page] == "user"
      respond_to do |format|
        format.js { render js: "window.location.reload();" }
      end
    end

    respond_to do |format|
      format.html { redirect_to edit_organization_path(@organization.identifier, tab: 'managers') }
      format.js
    end
  end

  def autocomplete_for_manager
    @managers = User.active.sorted.like(params[:q]).limit(100).to_a - @organization.managers
    render :layout => false
  end

end

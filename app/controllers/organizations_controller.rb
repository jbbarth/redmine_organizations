class OrganizationsController < ApplicationController
  unloadable
  
  layout 'admin'
  
  def index
    @organizations = Organization.all
  end
  
  def show
    @organization = Organization.find(params[:id])
  end
  
  def new
    @organization = Organization.new
  end
  
  def edit
    @organization = Organization.find(params[:id])
  end
  
  def create
    @organization = Organization.new(params[:organization])
    if @organization.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to(@organization)
    else
     render :action => "new"
    end
  end
  
  def update
    @organization = Organization.find(params[:id])
    if @organization.update_attributes(params[:organization])
      flash[:notice] = l(:notice_successful_update)
      redirect_to(@organization)
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @organization = Organization.find(params[:id])
    @organization.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to(organizations_url)
  end
end

class OrganizationMembershipsController < ApplicationController
  before_filter :require_admin

  helper :organizations
  include OrganizationsHelper   
  
  def create
    @organization = Organization.find(params[:membership][:organization_id])
    @membership = OrganizationMembership.new(params[:membership])
    @membership.save
    respond_to do |format|
       format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization, :tab => 'memberships' }
       format.js { 
         render(:update) {|page| 
           page.replace_html "tab-content-memberships", :partial => 'organizations/memberships'
           page.visual_effect(:highlight, "member-#{@membership.id}")
         }
       }
     end
  end
  
  def update
    @organization = Organization.find(params[:id])
    @membership = OrganizationMembership.find(params[:membership_id])
    @membership.update_attributes(params[:membership])
    respond_to do |format|
       format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization, :tab => 'memberships' }
       format.js { 
         render(:update) {|page| 
           page.replace_html "tab-content-memberships", :partial => 'organizations/memberships'
           page.visual_effect(:highlight, "member-#{@membership.id}")
         }
       }
     end
  end
  
  def destroy
    @organization = Organization.find(params[:id])
    OrganizationMembership.find(params[:membership_id]).destroy
    respond_to do |format|
      format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization, :tab => 'memberships' }
      format.js { render(:update) {|page| page.replace_html "tab-content-memberships", :partial => 'organizations/memberships'} }
    end
  end
end

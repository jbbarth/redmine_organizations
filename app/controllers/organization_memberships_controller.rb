class OrganizationMembershipsController < ApplicationController
  before_filter :require_admin

  helper :organizations
  include OrganizationsHelper   
  
  def create
    @membership = OrganizationMembership.new(params[:membership])
    @membership.save
    @organization = @membership.organization
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
    @membership = OrganizationMembership.find(params[:id])
    @membership.update_attributes(params[:membership])
    @organization = @membership.organization
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
    membership = OrganizationMembership.find(params[:id]).destroy
    @organization = membership.organization
    respond_to do |format|
      format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization, :tab => 'memberships' }
      format.js { render(:update) {|page| page.replace_html "tab-content-memberships", :partial => 'organizations/memberships'} }
    end
  end
end

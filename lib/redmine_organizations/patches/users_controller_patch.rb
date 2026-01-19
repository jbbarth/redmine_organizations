require_dependency 'users_controller'

module RedmineOrganizations::Patches
  module UsersControllerPatch

    def create

      if params[:back_url].present?

        @back_url = params[:back_url]

        # Copy/Paste From Redmine Core
        @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option, :admin => false)
        @user.safe_attributes = params[:user]
        @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation] unless @user.auth_source_id
        @user.pref.safe_attributes = params[:pref]

        if @user.save
          Mailer.deliver_account_information(@user, @user.password) if params[:send_information]

          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_user_successful_create, :id => view_context.link_to(@user.login, user_path(@user)))
              if params[:continue]
                attrs = { :generate_password => @user.generate_password }
                redirect_to new_user_path(:user => attrs, back_url: @back_url)
              else
                redirect_back_or_default(user_path(@user))
              end
            }
            format.api { render :action => 'show', :status => :created, :location => user_url(@user) }
          end
        else
          @auth_sources = AuthSource.all
          # Clear password input
          @user.password = @user.password_confirmation = nil

          respond_to do |format|
            format.html { render :action => 'new', back_url: @back_url }
            format.api { render_validation_errors(@user) }
          end
        end

      else
        super
      end

    end

  end
end
UsersController.prepend RedmineOrganizations::Patches::UsersControllerPatch

class UsersController < ApplicationController

  before_action :require_admin, :except => [:show, :new, :create]
  before_action :require_admin_or_manager, :only => [:new, :create]
  after_action :update_memberships_according_to_new_orga, only: [:update]

  private

    def update_memberships_according_to_new_orga

      if @user.present? &&
          @user.errors.empty? &&
          params[:user][:orga_update_method].present? &&
          params[:user][:organization_id].present?

        case params[:user][:orga_update_method]
          when "remove" # Remove all memberships for this user
            Member.where(user_id: @user.id).destroy_all
          when "replace"
            other_memberships = []
            other_memberships = User.find(params[:copy_user]).memberships if params[:copy_user].present?
            Member.where(user_id: @user.id).destroy_all
            other_memberships.each do |membership|
              new_membership = Member.new(project_id: membership.project_id)
              membership.roles.each do |role|
                new_membership.roles << role
              end
              if Redmine::Plugin.installed?(:redmine_limited_visibility)
                membership.functions.each do |function|
                  new_membership.functions << function
                end
              end
              @user.memberships << new_membership
            end
        end
      end
    end
end

require_dependency 'users_controller'

class UsersController < ApplicationController

  after_filter :update_memberships_according_to_new_orga, only: [:update]

  private

    def update_memberships_according_to_new_orga

      if @user.present? &&
          @user.errors.empty? &&
          params[:user][:orga_update_method].present? &&
          params[:user][:organization_id].present?

        case params[:user][:orga_update_method]
          when "remove" # Remove all memberships for this user
            Member.destroy_all(user_id: @user.id)
          when "replace"
            other_memberships = User.find(params[:copy_user]).memberships
            Member.destroy_all(user_id: @user.id)
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

RedmineApp::Application.routes.draw do
  resources :organizations do
    member do
      post :add_users
      post :remove_user
      get :autocomplete_for_user
    end
    collection do
      get :autocomplete_user_from_id
      get :autocomplete_users
      get :ldap_sync
      post :ldap_sync_check_status
      get :add_organization_from_ldap
      post :add_all_organizations_from_ldap
      get :search
    end
  end
  namespace :organizations do
    resources :managers, only: [:create, :destroy] do
      collection do
        get :autocomplete_for_manager
      end
    end
    resources :team_leaders, only: [:update, :destroy] do
      collection do
        put :assign_to_team_projects
      end
    end
    resources :notifications, only: [:update]
    resources :memberships, only: [:new, :edit, :update] do
      collection do
        post :create_non_members_roles
        put :update_group_non_member_roles
      end
      member do
        put :update_non_members_roles
        put :update_non_members_functions
        delete :destroy_non_members_roles
        delete :destroy_organization
      end
    end
  end
  post 'users/:id/fetch_users_by_orga', :controller => 'organizations', :action => 'fetch_users_by_orga'
end

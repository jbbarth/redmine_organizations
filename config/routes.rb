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
    end
  end
  namespace :organizations do
    resources :managers, only: [:update]
    resources :team_leaders, only: [] do
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
        delete :destroy_non_members_roles
      end
    end
  end
  post 'users/:id/fetch_users_by_orga', :controller => 'organizations', :action => 'fetch_users_by_orga'
end

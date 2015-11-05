RedmineApp::Application.routes.draw do
  resources :organizations do
    member do
      post :add_users
      post :remove_user
      get :autocomplete_for_user
    end
    collection do
      get :autocomplete_user_from_id
      post :create_membership_in_project
      put :update_roles
      put :update_user_roles
      put :update_non_member_organization_roles
      delete :destroy_membership_in_project
      delete :destroy_overriden_non_membership_in_project
    end
  end
  post 'users/:id/fetch_users_by_orga', :controller => 'organizations', :action => 'fetch_users_by_orga'
end

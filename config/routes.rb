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
      delete :destroy_membership_in_project
    end
  end
end

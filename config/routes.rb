RedmineApp::Application.routes.draw do
  resources :organizations do
    member { post :add_users }
    member { post :remove_user }
    member { get :autocomplete_for_user }
    collection { get :autocomplete_user_from_id }
    collection { post :copy_user }
  end
  resources :organization_memberships, :only => [:create,:update,:destroy] do
    new { post :create_in_project }
    member { put :update_roles }
    member { put :update_users }
    member { delete :destroy_in_project }
  end
end

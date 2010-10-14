ActionController::Routing::Routes.draw do |map|
  map.resources :organizations, :member => {:add_users => :post,
                                            :remove_user => :post,
                                            :autocomplete_for_user => :post},
                                :collection => {:autocomplete_user_from_id => :post,
                                                :copy_user => :post}
  map.resources :organization_memberships, :only => [:create,:update,:destroy],
                                           :new => {:create_in_project => :post},
                                           :member => {:update_roles => :put,
                                                       :update_users => :put,
                                                       :destroy_in_project => :delete}
end

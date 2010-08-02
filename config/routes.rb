ActionController::Routing::Routes.draw do |map|
  map.resources :organizations, :member => {:add_users => :post,
                                            :remove_user => :post,
                                            :autocomplete_for_user => :post}
end

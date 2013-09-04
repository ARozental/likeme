Likeme::Application.routes.draw do
  
  #resources :users, only: :index
  #resources :user_page_relationships
  #get 'home/insert', :via => :get
  match '/users', to: 'users#index'
  match '/pages', to: 'home#pages'
  match '/events', to: 'home#events'
  get 'home/index', :via => :post
  match 'home/index' => 'home#index', :via => :post
  get 'home/ajax_matching', :via => :post
  match 'home/ajax_matching' => 'home#ajax_matching', :via => :post
  #get 'home/autocomplete_user_name', :via => :post
  #match 'home/autocomplete_user_name' => 'home#auto_complete_name', :via => :post
  root :to => 'home#index'
  
  match 'users', to: 'users#index'
  match 'auth/:provider/callback', to: 'sessions#create'
  match 'auth/failure', to: redirect('/')
  match 'signout', to: 'sessions#destroy', as: 'signout'
  #get 'client_address_joins/upload', :via => :post
  #match 'client_address_joins/upload' => 'client_address_joins#upload', :via => :post

  
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.


  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end

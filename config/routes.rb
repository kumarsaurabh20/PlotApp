#require 'api_constraints'


PlotApp::Application.routes.draw do

  root :to => "uploads#index"
 
  resources :predicts
  resources :uploads

  #upload routes
  match '/normalize' => 'uploads#normalize'
  match '/download_coeffs' => 'uploads#download_coeffs', via: :get
  match '/sample_calib_file' => 'uploads#download_sample_calib_file'
  match '/sample_probe_list' => 'uploads#download_sample_probe_list'
 
  #manual route 
  match '/download_manual' => 'uploads#download_manual', via: :get

  #Predict routes
  match '/calculate' => 'predicts#calculate'
  match '/download_cell_counts' => 'predicts#download_cell_counts', via: :get
  match '/download_sample_coeffs_file' => 'predicts#download_sample_coeffs_file', via: :get
  match '/download_sample_raw_inten_file' => 'predicts#download_sample_raw_inten_file', via: :get


################API ROUTES################
  #namespace :api, defaults: {format: 'json'} do
  #  scope module: :v1 do
  #    resources :uploads
  #  end
  #end
###########################################
#, constraints: ApiConstraints.new(version: 1)


  #resources :plots
  #match ':controller/:action/:id'
  #match ':controller/:action/:id.:format'
  #match '/get_coefficients.xml' => 'plots#cal_s2c'

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
   #root :to => "uploads#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'

  

end

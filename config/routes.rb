Rails.application.routes.draw do
  resources :programs
  get 'welcome/index'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'

  post 'saverelation', :to => 'relations#save_relation', :as => 'saverelation'
  post 'retrieverelation', :to => 'relations#retrieve_relation', :as => 'retrieverelation'
  post 'retrieverelations', :to => 'relations#retrieve_relations', :as => 'retrieverelations'
  post 'allpagerelations', :to => 'relations#all_page_relations', :as => 'allpagerelations'

  # for now a few ways to keep retrieving the old datasets, but should remove this block soon
  #post 'newdatasetsid', :to => 'datasets#new', :as => 'newdatasetsid'
  #get 'programfordataset/:id' => 'datasets#programfordataset'
  #post 'updatedataset', :to => 'datasets#updatedataset', :as => 'updatedataset'
  #post 'datasetslice', :to => 'datasets#save_slice', :as => 'datasetslice'
  #get 'datasetsold/:id' => 'datasets#download'
  #get 'datasetsforgiving/:id' => 'datasets#downloadforgiving'
  #get 'downloaddetailed/:id' => 'datasets#downloaddetailed'
  #get 'downloaddetailedallattributes/:id' => 'datasets#downloaddetailedallattributes'
  #get 'downloadmultipass/:id' => 'datasets#downloadmultipass'
  #get 'downloadmultipassforgiving/:id' => 'datasets#downloadmultipassforgiving'
  #get 'downloaddetailedmultipass/:id' => 'datasets#downloaddetailedmultipass'
  #get 'datasets/runnostream/:id' => 'program_runs#download_run_old', :defaults => { :format => 'csv' }
  #get 'datasets/rundetailednostream/:id' => 'program_runs#download_run_detailed_old', :defaults => { :format => 'csv' }

  post 'newprogramrun', :to => 'program_runs#new', :as => 'newprogramrun'
  post 'newprogramsubrun', :to => 'program_runs#new_sub_run', :as => 'newprogramsubrun'
  post 'updaterunname', :to => 'program_runs#update_run_name', :as => 'updaterunname'
  post 'datasetslice', :to => 'program_runs#save_slice', :as => 'datasetslice'
  
  # the current allowable ways to download
  get 'datasets/run/:id' => 'program_runs#download_run', :defaults => { :format => 'csv' }
  get 'datasets/rundetailed/:id' => 'program_runs#download_run_detailed', :defaults => { :format => 'csv' }
  get 'datasets/:id' => 'program_runs#download_all_runs', :defaults => { :format => 'csv' }

  post 'saveprogram', :to => 'programs#save_program', :as => 'saveprogram'

  post 'newtransaction', :to => 'transaction_records#new', :as => 'newtransaction'
  post 'newtransactionwithdata', :to => 'transaction_records#new_with_dataset_slice', :as => 'newtransactionwithdata'
  post 'transactionexists', :to => 'transaction_records#exists', :as => 'transactionexists'
  post 'locktransaction', :to => 'transaction_locks#make_if_not_exists', :as => 'locktransaction'

  resources :relations
  resources :columns

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end

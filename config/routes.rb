Rails.application.routes.draw do
  root "products#index" # Set the root to the products#index action
  resources :products do
    collection do
      post :import       # For importing CSV files
      post :bulk_update  # For bulk updating supplier data
      get :export        # For exporting data to a CSV
      get :clear         # To clear the uploaded CSV data
    end
  end
end

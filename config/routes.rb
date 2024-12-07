Rails.application.routes.draw do
  root "products#index" # Root path to display product data or upload form
  resources :products do
    collection do
      post :import       # Route for importing CSV
      post :bulk_update  # Route for bulk updating supplier data
      get :export        # Route for exporting data to a CSV
      get :clear         # Route for clearing current session data
    end
  end
end

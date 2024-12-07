Rails.application.routes.draw do
  resources :products do
    collection do
      post :import
      post :bulk_update
    end
  end
  root "products#index"
end

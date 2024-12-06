Rails.application.routes.draw do
  resources :products do
    collection do
      post :import
      get :export
    end
  end
  root "products#index"
end

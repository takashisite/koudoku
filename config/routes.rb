Koudoku::Engine.routes.draw do
  # e.g. :users
  resources :subscriptions, only: [:new]
  resources :checkouts, only: [:create,:edit]
  resources Koudoku.owner_resource, as: :owner do
    resources :subscriptions do
      member do
        post :cancel
      end
    end
    resources :checkouts
  end
  resources :webhooks, only: [:create]
end

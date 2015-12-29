Rails.application.routes.draw do
  root  'customers#home'
  get   '/login', to: 'sessions#new'
  post  '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  get '/new-building-kit-location', to: 'customers#new_building_kit_location'
  post '/building-kit-location', to: 'customers#store_building_kit_location'

  resources :customers, only: [:new, :create] do
    member do
      get '/item-pricing', to: 'items#get_item_pricing'
    end

    resources :items, except: [:new, :show]
  end
end

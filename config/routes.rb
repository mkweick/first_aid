Rails.application.routes.draw do
  root  'customers#home'
  get   '/login', to: 'sessions#new'
  post  '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  get '/new-building-kit', to: 'customers#new_building_kit_location'
  post '/building-kit', to: 'customers#store_building_kit_location'

  resources :customers, only: [:new, :create] do
    resources :items, except: [:new]
  end
end

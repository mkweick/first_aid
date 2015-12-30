Rails.application.routes.draw do
  root    'customers#home'
  get     '/login',   to: 'sessions#new'
  post    '/login',   to: 'sessions#create'
  delete  '/logout',  to: 'sessions#destroy'

  get     '/kit-location', to: 'sessions#set_kit_location'
  post    '/kit-location', to: 'sessions#store_kit_location'

  resources :customers, only: [:new, :create] do
    member do
      get '/pick-ticket',   to: 'customers#print_pick_ticket'
      get '/receipt',       to: 'customers#print_customer_receipt'
      get '/item-pricing',  to: 'items#get_pricing'
    end

    resources :items, except: [:new, :show]
  end
end

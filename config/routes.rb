Rails.application.routes.draw do
  root    'customers#home'
  get     '/login',         to: 'sessions#new'
  post    '/login',         to: 'sessions#create'
  delete  '/logout',        to: 'sessions#destroy'

  get     '/kit-location',  to: 'sessions#set_kit_location'
  post    '/kit-location',  to: 'sessions#store_kit_location'

  resources :customers, only: [:new, :create] do
    member do
      get   '/ship-to',       to: 'customers#select_ship_to'
      post  '/ship-to',       to: 'customers#set_ship_to'
      post  '/po_number',     to: 'customers#po_number'
      get   '/pick-ticket',   to: 'customers#print_pick_ticket'
      get   '/customer-copy', to: 'customers#print_customer_copy'
      get   '/email-address', to: 'customers#get_email_address'
      post  '/send-email',    to: 'customers#email_customer_copy'
      post  '/submit-order',  to: 'customers#complete_order'
      get   '/item-pricing',  to: 'items#get_pricing'
    end

    resources :items, except: [:new, :show]
  end
end

Rails.application.routes.draw do
  root    'customers#home'
  get     '/login',         to: 'sessions#new'
  post    '/login',         to: 'sessions#create'
  delete  '/logout',        to: 'sessions#destroy'

  get     '/kit-location',  to: 'sessions#set_kit_location'
  post    '/kit-location',  to: 'sessions#store_kit_location'

  resources :customers, only: [:new, :create] do
    member do
      get     '/ship-to',       to: 'customers#select_ship_to'
      post    '/ship-to',       to: 'customers#set_ship_to'
      get     '/checkout',      to: 'customers#checkout'
      get     '/po-number',     to: 'customers#po_number'
      post    '/po-number',     to: 'customers#create_po_number'
      post    '/card-on-file',  to: 'customers#set_card_on_file'
      delete  '/card-on-file',  to: 'customers#remove_card_on_file'
      get     '/pick-ticket',   to: 'customers#print_pick_ticket'
      get     '/customer-copy', to: 'customers#print_customer_copy'
      get     '/email-address', to: 'customers#get_email_address'
      post    '/send-email',    to: 'customers#email_customer_copy'
      post    '/submit-order',  to: 'customers#complete_order'
      get     '/item-pricing',  to: 'items#get_pricing'
    end

    resources :items, except: [:new, :show]
    resources :credit_cards, except: [:index, :show]
  end
end

Rails.application.routes.draw do
  root  'orders#new'
  get   '/login', to: 'sessions#new'
  post  '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
end

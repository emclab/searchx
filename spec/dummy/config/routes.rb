Rails.application.routes.draw do

  mount Searchx::Engine => "/searchx"
  mount Authentify::Engine => "/authentify"
  mount Commonx::Engine => "/commonx"
  
  #resource :session
  
  root :to => "sessions#new", controller: :authentify
  get '/signin',  :to => 'sessions#new', controller: :authentify
  get '/signout', :to => 'sessions#destroy', controller: :authentify
  get '/user_menus', :to => 'user_menus#index', controller: :main_app
  get '/view_handler', :to => 'application#view_handler', controller: :authentify
end

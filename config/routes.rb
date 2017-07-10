# frozen_string_literal: true

Rails.application.routes.draw do
  scope module: :v1, constraints: APIVersion.new(version: 1, current: true) do
    # Account
    post  '/login',                       to: 'sessions#create'
    post  '/register',                    to: 'registrations#create'
    post  '/reset-password',              to: 'passwords#create'
    post  '/users/password',              to: 'passwords#update_by_token'
    patch '/users/current-user/password', to: 'passwords#update'

    # Helper requests
    get '/users/current-user',  to: 'users#current'

    scope '(:locale)', locale: /en|fr/ do
      # Resources
      jsonapi_resources :users do; end
      jsonapi_resources :countries do; end
      jsonapi_resources :categories do; end
      jsonapi_resources :species do; end
      jsonapi_resources :operators do; end
      jsonapi_resources :governments do; end
      jsonapi_resources :observers do; end
      jsonapi_resources :observations do; end
      resources :fmus, only: :index
      resources :contacts, only: [:create, :index]

      get 'observation_filters', to: 'observation_filters#index'


    end
  end
end

# frozen_string_literal: true

Rails.application.routes.draw do
  scope module: :v1, constraints: APIVersion.new(version: 1, current: true) do
    # Account
    post '/login',    to: 'sessions#create'
    post '/register', to: 'registrations#create'

    # Helper requests
    get '/users/current-user',  to: 'current_user#show'

    scope '(:locale)', locale: /en|fr/ do
      # Resources
      resources :users
      resources :countries
      resources :categories
      resources :species
      resources :operators
      resources :laws
      resources :governments

      resources :annex_operators do
        resources :comments, only: [:create, :destroy], on: :member, as: :comment
      end

      resources :annex_governances do
        resources :comments, only: [:create, :destroy], on: :member, as: :comment
      end

      resources :observers
      resources :observations
    end
  end
end

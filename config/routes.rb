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
    get '/users/current-user',  to: 'current_user#show'

    scope '(:locale)', locale: /en|fr/ do
      # Resources
      resources :users
      resources :countries
      resources :categories
      resources :species
      resources :operators
      resources :governments
      resources :observers
      resources :fmus, only: :index
      resources :contacts, only: [:create, :index]

      get 'observation_filters', to: 'observation_filters#index'

      resources :observations do
        resources :comments, only: [:create, :destroy], on: :member, as: :comment
      end

      resources :annex_operators do
        resources :comments, only: [:create, :destroy], on: :member, as: :comment
      end

      resources :annex_governances do
        resources :comments, only: [:create, :destroy], on: :member, as: :comment
      end
    end
  end
end

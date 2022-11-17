# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self) rescue ActiveAdmin::DatabaseHitDuringLoad

  root to: 'home#index'

  match 'admin/fmus/preview' => 'admin/fmus#preview', via: :post

  require 'sidekiq/web'
  authenticate :user, ->(user) { user&.user_permission&.user_role == 'admin' } do
    mount Sidekiq::Web => '/admin/sidekiq'
  end

  get '/private/uploads/*rest', controller: 'private_uploads', action: 'download'

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
      jsonapi_resources :about_page_entries, only: [:index, :show]
      jsonapi_resources :categories
      jsonapi_resources :countries
      jsonapi_resources :country_links, only: [:index, :show]
      jsonapi_resources :country_vpas, only: [:index, :show]
      jsonapi_resources :donors
      jsonapi_resources :faqs, only: [:index, :show]
      jsonapi_resources :governments
      jsonapi_resources :gov_documents
      jsonapi_resources :gov_files, only: [:create, :destroy]
      jsonapi_resources :how_tos, only: [:index, :show]
      jsonapi_resources :laws
      jsonapi_resources :notifications, only: [:index] do
        put :dismiss, on: :member
      end
      jsonapi_resources :observations
      jsonapi_resources :observation_documents
      jsonapi_resources :observation_reports
      jsonapi_resources :observers
      jsonapi_resources :operators
      jsonapi_resources :operator_documents, except: [:create, :update]
      jsonapi_resources :operator_document_annexes
      jsonapi_resources :operator_document_countries, except: [:create]
      jsonapi_resources :operator_document_fmus, except: [:create]
      jsonapi_resources :operator_document_histories
      jsonapi_resources :partners
      jsonapi_resources :required_gov_documents
      jsonapi_resources :required_operator_documents
      jsonapi_resources :required_operator_document_groups
      jsonapi_resources :sawmills
      jsonapi_resources :score_operator_documents, only: [:index]
      jsonapi_resources :severities, only: [:index, :show]
      jsonapi_resources :species
      jsonapi_resources :subcategories
      jsonapi_resources :tools, only: [:index, :show]
      jsonapi_resources :tutorials, only: [:index, :show]
      jsonapi_resources :users

      resources :fmus, only: [:index, :update] do
        get 'tiles/:z/:x/:y', to: 'fmus#tiles', on: :collection
      end

      resources :imports, only: :create

      get 'observation_filters_tree', to: 'observation_filters#tree'
      get 'operator_document_filters_tree', to: 'operator_document_filters#tree'
    end

    # Documentation
    mount Rswag::Api::Engine => 'docs'
    mount Rswag::Ui::Engine => 'docs'
  end
end

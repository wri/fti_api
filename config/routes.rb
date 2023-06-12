# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, ActiveAdmin::Devise.config
  begin
    ActiveAdmin.routes(self)
  rescue
    ActiveAdmin::DatabaseHitDuringLoad
  end

  root to: "home#index"

  post "admin/fmus/preview" => "admin/fmus#preview"

  require "sidekiq/web"

  if Rails.env.development?
    mount Sidekiq::Web => "/admin/sidekiq"
    mount LetterOpenerWeb::Engine, at: "/admin/letter_opener"
  else
    authenticate :user, ->(user) { user&.user_permission&.user_role == "admin" } do
      mount Sidekiq::Web => "/admin/sidekiq"
      mount LetterOpenerWeb::Engine, at: "/admin/letter_opener" if Rails.env.staging?
    end
  end

  get "/private/uploads/*rest", controller: "private_uploads", action: "download"

  scope module: :v1, constraints: APIVersion.new(version: 1, current: true) do
    # Account
    post "/login", to: "sessions#create"
    post "/register", to: "registrations#create"
    post "/reset-password", to: "passwords#create"
    post "/users/password", to: "passwords#update"

    # Helper requests
    get "/users/current-user", to: "users#current"

    scope "(:locale)", locale: /en|fr/ do
      # Resources
      # keep empty blocks to not generate relationships routes
      # https://jsonapi-resources.com/v0.9/guide/routing.html#Nested-Routes
      # Big plus of generating relationships routes is that it validates configured
      # relationships, but it's better to keep API smaller
      # rubocop:disable Standard/BlockSingleLineBraces
      jsonapi_resources :about_page_entries, only: [:index, :show] do; end
      jsonapi_resources :categories, only: [:index, :show] do; end
      jsonapi_resources :countries, only: [:index, :show] do; end
      jsonapi_resources :country_links, only: [:index, :show] do; end
      jsonapi_resources :country_vpas, only: [:index, :show] do; end
      jsonapi_resources :donors, only: [:index, :show] do; end
      jsonapi_resources :faqs, only: [:index, :show] do; end
      jsonapi_resources :governments do; end
      jsonapi_resources :gov_documents, except: [:create] do; end
      jsonapi_resources :how_tos, only: [:index, :show] do; end
      jsonapi_resources :laws do; end
      jsonapi_resources :notifications, only: [:index] do
        put :dismiss, on: :member
      end
      jsonapi_resources :observations do; end
      jsonapi_resources :observation_documents do; end
      jsonapi_resources :observation_reports do; end
      jsonapi_resources :observers, only: [:index, :show] do; end
      jsonapi_resources :operators do; end
      jsonapi_resources :operator_documents, except: [:create, :update] do; end
      jsonapi_resources :operator_document_countries, except: [:create] do; end
      jsonapi_resources :operator_document_fmus, except: [:create] do; end
      jsonapi_resources :operator_document_annexes do; end
      jsonapi_resources :operator_document_histories do; end
      jsonapi_resources :partners, only: [:index, :show] do; end
      jsonapi_resources :sawmills do; end
      jsonapi_resources :score_operator_documents, only: [:index] do; end
      jsonapi_resources :severities, only: [:index, :show] do; end
      jsonapi_resources :species, only: [:index, :show] do; end
      jsonapi_resources :subcategories, only: [:index, :show] do; end
      jsonapi_resources :tools, only: [:index, :show] do; end
      jsonapi_resources :tutorials, only: [:index, :show] do; end
      jsonapi_resources :users do; end
      # rubocop:enable Standard/BlockSingleLineBraces

      resources :fmus, only: [:index, :update] do
        get "tiles/:z/:x/:y", to: "fmus#tiles", on: :collection
      end

      resources :imports, only: :create

      get "observation_filters_tree", to: "observation_filters#tree"
      get "operator_document_filters_tree", to: "operator_document_filters#tree"
    end

    # Documentation
    mount Rswag::Api::Engine => "docs"
    mount Rswag::Ui::Engine => "docs"
  end
end

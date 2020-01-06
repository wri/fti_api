# frozen_string_literal: true

module V1
  class ObserverResource < JSONAPI::Resource
    include CachableByLocale
    caching
    attributes :observer_type, :name, :organization, :is_active, :logo, :address,
               :information_name, :information_email, :information_phone, :data_name,
               :data_email, :data_phone, :organization_type, :delete_logo

    has_many :countries
    has_many   :users
    has_many :observations

    filters :countries, :is_active

    before_create :inactivate

    def inactivate
      @model.is_active = false
    end


    def custom_links(_)
      { self: nil }
    end

    def fetchable_fields
      super - [:delete_logo]
    end

    def self.updatable_fields(context)
      super - [:is_active]
    end
    def self.creatable_fields(context)
      super - [:is_active]
    end

    def self.records(options = {})
      Observer.active
    end
  end
end

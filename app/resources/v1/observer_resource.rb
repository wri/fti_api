# frozen_string_literal: true

module V1
  class ObserverResource < BaseResource
    include CacheableByLocale
    # caching

    attributes :observer_type, :name, :is_active, :address,
      :information_name, :information_email, :information_phone, :data_name,
      :data_email, :data_phone, :organization_type, :public_info

    has_many :countries
    has_many :observations

    filters :countries, :is_active

    before_create :inactivate

    def inactivate
      @model.is_active = false
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

    def fetchable_fields
      if (context[:app] == "observations-tool") || @model.public_info
        super
      else
        super - [:address, :information_name, :information_email, :information_phone, :data_email, :data_phone, :data_name]
      end
    end
  end
end

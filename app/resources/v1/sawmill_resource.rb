# frozen_string_literal: true

module V1
  class SawmillResource < JSONAPI::Resource
    caching
    immutable
    attributes :name, :lat, :lng, :is_active, :geojson

    has_one :operator

    filters :operator, :name, :is_active

    def self.sortable_fields(context)
      super + [:'operator.name']
    end

    filter :'operator.name', apply: ->(records, value, _options) {
      if value.present?
        sanitized_value = ActiveRecord::Base.connection.quote("%#{value[0].downcase}%")
        records.joins(:operator).joins([operator: :translations]).where("lower(operator_translations.name) like #{sanitized_value}")
      else
        records
      end
    }


    def self.updatable_fields(context)
      super - [:geojson]
    end

    def self.creatable_fields(context)
      super - [:geojson]
    end


    def self.records(options = {})
      Sawmill.active
    end

    def custom_links(_)
      { self: nil }
    end

    # Adds the locale to the cache
    def self.attribute_caching_context(context)
      {
          locale: context[:locale]
      }
    end
  end
end

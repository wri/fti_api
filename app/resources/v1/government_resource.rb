# frozen_string_literal: true

module V1
  class GovernmentResource < JSONAPI::Resource
    caching

    attributes :government_entity, :details

    has_one :country

    def self.sortable_fields(context)
      super + [:'country.name']
    end

    filters :country

    filter :'country.name', apply: ->(records, value, _options) {
      if value.present?
        sanitized_value = ActiveRecord::Base.connection.quote("%#{value[0].downcase}%")
        records.joins(:country).joins([country: :translations]).where("lower(country_translations.name) like #{sanitized_value}")
      else
        records
      end
    }

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

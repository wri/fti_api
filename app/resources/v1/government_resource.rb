# frozen_string_literal: true

module V1
  class GovernmentResource < JSONAPI::Resource
    include CacheableByLocale
    include ObsToolFilter
    caching

    attributes :government_entity, :details, :is_active

    has_one :country

    def self.sortable_fields(context)
      super + [:'country.name']
    end

    filters :country, :is_active

    filter :'country.name', apply: ->(records, value, _options) {
      if value.present?
        sanitized_value = ActiveRecord::Base.connection.quote("%#{value[0].downcase}%")
        records.joins(:country).joins([country: :translations]).where("lower(country_translations.name) like #{sanitized_value}")
      else
        records
      end
    }

    def self.obs_tool_filter_scope(records, user)
      records.where(
        id: Observation.own_with_inactive(user.observer_id)
          .joins(:governments)
          .select('governments.id')
          .distinct
          .pluck('governments.id')
      )
    end

    def custom_links(_)
      { self: nil }
    end
  end
end

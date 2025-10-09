# frozen_string_literal: true

module V1
  class GovernmentResource < BaseResource
    include CacheableByLocale
    caching

    attributes :government_entity, :details, :is_active

    has_one :country

    def self.sortable_fields(context)
      super + [:"country.name"]
    end

    filters :country, :is_active

    filter :"country.name", apply: ->(records, value, _options) {
      if value.present?
        pattern = "%#{value[0].downcase}%"
        records.joins(:country).joins([country: :translations]).where("lower(country_translations.name) like ?", pattern)
      else
        records
      end
    }

    filter :observer_id, apply: ->(records, value, _options) {
      records.where(
        id: Observation.own_with_inactive(value[0].to_i)
          .joins(:governments)
          .select("governments.id")
          .distinct
          .select("governments.id")
      )
    }
  end
end

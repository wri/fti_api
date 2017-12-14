# frozen_string_literal: true

module V1
  class FmuResource < JSONAPI::Resource
    caching
    paginator :none

    attributes :name, :geojson, :certification_fsc, :certification_pefc, :certification_olb

    has_one :country
    has_one :operator

    filters :country, :free, :certification

    def custom_links(_)
      { self: nil }
    end

    filter :certification, apply: ->(records, value, _options) {
      records = records.with_certification_fsc       if value.include?('fsc')
      records = records.with_certification_pefc      if value.include?('pefc')
      records = records.with_certification_olb       if value.include?('olb')

      records
    }

    filter :free, apply: ->(records, value, _options) {
      records = records.filter_by_free

      records
    }

    # Adds the locale to the cache
    def self.attribute_caching_context(context)
      {
          locale: context[:locale]
      }
    end

  end
end

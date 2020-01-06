# frozen_string_literal: true

module V1
  class CountryResource < JSONAPI::Resource
    include CachableByLocale
    caching

    attributes :iso, :region_iso, :country_centroid,
               :region_centroid, :is_active, :region_name, :name,
               :percentage_valid_documents

    has_many :fmus
    has_many :required_operator_documents
    has_many :required_gov_documents
    has_many :governments
    has_many :monitors

    filter :iso
    filter :is_active, default: 'true',
                       apply: ->(records, value, _options) {
             if %w(true false).include?(value.first)
               records.where(is_active: value.first)
             else
               records
             end
           }

    def custom_links(_)
      { self: nil }
    end
  end
end

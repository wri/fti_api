# frozen_string_literal: true

module V1
  class SubcategoryResource < JSONAPI::Resource
    caching

    attributes :name, :details, :subcategory_type, :category_id

    has_one :category
    has_many :severities
    has_many :country_subcategories
    has_many :observations

    filters :id, :name, :subcategory_type, :category_id

    filter :observation_type, apply:->(records, value, _options) {
      records.joins(:observations).where('observations.observation_type = ?', value[0].to_i)
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

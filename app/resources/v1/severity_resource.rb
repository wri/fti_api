# frozen_string_literal: true

module V1
  class SeverityResource < JSONAPI::Resource
    caching
    attributes :level, :details

    filters :id, :level, :subcategory

    has_one :subcategory
    has_many :observations

    def self.sortable_fields(context)
      super + [:'subcategory.name']
    end

    filter :subcategory_type, apply: ->(records, value, _options) {
      records.joins(:subcategory).where('subcategories.subcategory_type = ?', value[0].to_i)
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

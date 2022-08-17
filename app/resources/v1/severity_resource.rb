# frozen_string_literal: true

module V1
  class SeverityResource < JSONAPI::Resource
    include CacheableByLocale
    include ObsToolFilter

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

    def self.obs_tool_filter_scope(records, user)
      records.where(
        id: Observation.own_with_inactive(user.observer_id).select(:severity_id).distinct.pluck(:severity_id)
      )
    end
  end
end

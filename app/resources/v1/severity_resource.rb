# frozen_string_literal: true

module V1
  class SeverityResource < JSONAPI::Resource
    include CacheableByLocale
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

    filter :for_obs_tool_filter, apply: ->(records, value, options) {
      context = options[:context]
      user = context[:current_user]
      app = context[:app]

      next records unless app == 'observations-tool'
      next records unless user.present? || user.observer_id.present?

      records.where(
        id: Observation.own_with_inactive(user.observer_id).select(:severity_id).distinct.pluck(:severity_id)
      )
    }

    def custom_links(_)
      { self: nil }
    end
  end
end

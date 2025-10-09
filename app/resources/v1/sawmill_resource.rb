# frozen_string_literal: true

module V1
  class SawmillResource < BaseResource
    include CacheableByLocale
    caching
    attributes :name, :lat, :lng, :is_active, :geojson

    has_one :operator

    filters :operator, :name, :is_active

    before_create :set_operator_id

    def set_operator_id
      if context[:current_user].present? && context[:current_user].operator_id.present?
        @model.operator_id = context[:current_user].operator_id
      end
    end

    def self.sortable_fields(context)
      super + [:"operator.name"]
    end

    filter :"operator.name", apply: ->(records, value, _options) {
      if value.present?
        pattern = "%#{value[0].downcase}%"
        records.joins(:operator).joins([operator: :translations]).where("lower(operator_translations.name) like ?", pattern)
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
  end
end

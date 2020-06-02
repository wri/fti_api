# frozen_string_literal: true

module V1
  class RequiredOperatorDocumentFmuResource < JSONAPI::Resource
    include CacheableByLocale
    caching
    attributes :forest_types, :name, :valid_period, :explanation, :forest_type

    has_one :country
    has_one :required_operator_document_group
    has_many :operator_document_fmus

    filters :name, :type

    def forest_types
      return if @model.forest_types.blank?

      @model.forest_types.map do |f|
        Fmu::FOREST_TYPES[f.to_sym][:geojson_label]
      end
    end

    def custom_links(_)
      { self: nil }
    end
  end
end

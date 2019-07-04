# frozen_string_literal: true

module V1
  class RequiredOperatorDocumentFmuResource < JSONAPI::Resource
    caching
    attributes :forest_type, :name, :valid_period, :explanation

    has_one :country
    has_one :required_operator_document_group
    has_many :operator_document_fmus

    filters :name, :type

    def forest_type
      Fmu::FOREST_TYPES[@model.forest_type.to_sym][:geojson_label] if @model.forest_type
    end

    def custom_links(_)
      { self: nil }
    end
  end
end

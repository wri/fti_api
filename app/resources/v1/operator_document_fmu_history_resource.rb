# frozen_string_literal: true

module V1
  class OperatorDocumentFmuHistoryResource < OperatorDocumentHistoryResource
    has_one :required_operator_document_fmu

    def forest_type
      rod = @model.required_operator_document
      Fmu::FOREST_TYPES[rod.forest_type.to_sym][:geojson_label] if rod.forest_type
    end
  end
end

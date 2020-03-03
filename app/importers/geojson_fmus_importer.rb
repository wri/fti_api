# frozen_string_literal: true

class GeojsonFmusImporter < FileDataImport::BaseImporter
  PERMITTED_ATTRIBUTES = %i[geojson].freeze

  record Fmu, permitted_attributes: PERMITTED_ATTRIBUTES, can: %i[update]
end

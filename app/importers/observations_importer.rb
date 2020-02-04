# frozen_string_literal: true

class ObservationsImporter < FileDataImport::BaseImporter
  PERMITED_ATTRIBBUTES = %i[
    observation_type publication_date pv is_active lat lng fmu_id
    location_information created_at updated_at
    actions_taken validation_status is_physical_place
  ].freeze

  PERMITED_TRANSLATES = %i[
    details evidence concern_opinion litigation_status
  ].freeze


  record Observation, permited_attributes: PERMITED_ATTRIBBUTES, permited_translations: PERMITED_TRANSLATES

  belongs_to Country, permited_attributes: %i[iso],  permited_translations: %i[name]

  belongs_to Operator,
             permited_attributes: %i[approved operator_type concession is_active logo website address delete_logo],
             permited_translations: %i[name details], can: %i[create]
end

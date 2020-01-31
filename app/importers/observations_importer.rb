# frozen_string_literal: true

class ObservationsImporter < FileDataImporter::Base
  PERMITED_ATTRIBBUTES = %i[
    observation_type publication_date pv is_active lat lng country_id fmu_id
    location_information subcategory_id severity_id created_at updated_at
    actions_taken validation_status is_physical_place
  ].freeze

  PERMITED_TRANSLATES = %i[
    details evidence concern_opinion litigation_status
  ].freeze


  define_record Observation, PERMITED_ATTRIBBUTES, PERMITED_TRANSLATES

  belongs_to Country, %i[iso], %i[name]
end

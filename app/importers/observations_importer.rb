# frozen_string_literal: true

class ObservationsImporter < FileDataImporter::Base
  define_record Observation, %i[
    observation_type publication_date pv is_active details evidence
    concern_opinion litigation_status lat lng country_id fmu_id
    location_information subcategory_id severity_id created_at updated_at
    actions_taken validation_status is_physical_place
  ]

  # belongs_to Country, permited_attributes: %i[name iso], permited_translations: %i[]
end

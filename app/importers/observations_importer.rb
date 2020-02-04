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

  USER_PERMITED_ATTRIBUTES = %i[
    name email nickname institution is_active deactivated_at
    web_url permissions_request permissions_accepted
  ].freeze


  record Observation, permited_attributes: PERMITED_ATTRIBBUTES, permited_translations: PERMITED_TRANSLATES

  belongs_to Country, permited_attributes: %i[iso],  permited_translations: %i[name], required: true
  belongs_to Severity, permited_attributes: %i[level], permited_translations: %i[details]
  belongs_to Government, permited_attributes: %i[is_active], permited_translations: %i[government_entity details]
  belongs_to ObservationReport, permited_attributes: %i[title publication_date created_at updated_at attachment]
  belongs_to User, permited_attributes: USER_PERMITED_ATTRIBUTES
  belongs_to User, as: :modified_user, permited_attributes: USER_PERMITED_ATTRIBUTES

  belongs_to Subcategory, permited_attributes: %i[subcategory_type category_id location_required],
                          permited_translations: %i[name details]

  belongs_to Law,
             permited_attributes: %i[
               written_infraction infraction sanctions min_fine max_fine
               penal_servitude other_penalties apv complete currency
             ]

  belongs_to Fmu,
             permited_attributes: %i[
               geojson forest_type certification_fsc certification_pefc
               certification_olb certification_vlc certification_vlo certification_tltv
             ],
             permited_translations: %i[name]

  belongs_to Operator,
             permited_attributes: %i[approved operator_type concession is_active logo website address delete_logo],
             permited_translations: %i[name details], can: %i[create]
end

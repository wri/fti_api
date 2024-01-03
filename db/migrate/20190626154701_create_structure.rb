# rubocop:disable all
# frozen_string_literal: true

class CreateStructure < ActiveRecord::Migration[5.0]
  def change
    return if table_exists?("active_admin_comments") # To make sure it's not executed

    # These are extensions that must be enabled in order to support this database
    enable_extension "postgis"
    enable_extension "plpgsql"
    enable_extension "address_standardizer"
    enable_extension "address_standardizer_data_us"
    enable_extension "citext"
    enable_extension "fuzzystrmatch"
    enable_extension "postgis_tiger_geocoder"
    enable_extension "postgis_topology"

    create_table "active_admin_comments", if_not_exists: true do |t|
      t.string "namespace"
      t.text "body"
      t.string "resource_type"
      t.integer "resource_id"
      t.string "author_type"
      t.integer "author_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
      t.index ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
      t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree
    end

    create_table "api_keys", if_not_exists: true do |t|
      t.string "access_token"
      t.datetime "expires_at"
      t.integer "user_id"
      t.boolean "is_active", default: true
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["access_token"], name: "index_api_keys_on_access_token", unique: true, using: :btree
      t.index ["user_id"], name: "index_api_keys_on_user_id", using: :btree
    end

    create_table "categories", if_not_exists: true do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "category_type"
    end

    create_table "category_translations", if_not_exists: true do |t|
      t.integer "category_id", null: false
      t.string "locale", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "name"
      t.index ["category_id"], name: "index_category_translations_on_category_id", using: :btree
      t.index ["locale"], name: "index_category_translations_on_locale", using: :btree
    end

    create_table "comments", if_not_exists: true do |t|
      t.integer "commentable_id"
      t.string "commentable_type"
      t.text "body"
      t.integer "user_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type", using: :btree
      t.index ["user_id"], name: "index_comments_on_user_id", using: :btree
    end

    create_table "contacts", if_not_exists: true do |t|
      t.string "name"
      t.string "email"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "contributor_translations", if_not_exists: true do |t|
      t.integer "contributor_id", null: false
      t.string "locale", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "name", null: false
      t.text "description"
      t.index ["contributor_id"], name: "index_contributor_translations_on_contributor_id", using: :btree
      t.index ["locale"], name: "index_contributor_translations_on_locale", using: :btree
    end

    create_table "contributors", if_not_exists: true do |t|
      t.string "website"
      t.string "logo"
      t.integer "priority"
      t.integer "category"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "type", default: "Partner"
      t.index ["type"], name: "index_contributors_on_type", using: :btree
    end

    create_table "countries", if_not_exists: true do |t|
      t.string "iso"
      t.string "region_iso"
      t.jsonb "country_centroid"
      t.jsonb "region_centroid"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "is_active", default: false, null: false
      t.index ["is_active"], name: "index_countries_on_is_active", using: :btree
      t.index ["iso"], name: "index_countries_on_iso", using: :btree
    end

    create_table "countries_observers", id: false do |t|
      t.integer "country_id", null: false
      t.integer "observer_id", null: false
      t.index ["country_id", "observer_id"], name: "index_countries_observers_on_country_id_and_observer_id", using: :btree
      t.index ["country_id", "observer_id"], name: "index_unique_country_observer", unique: true, using: :btree
      t.index ["observer_id", "country_id"], name: "index_countries_observers_on_observer_id_and_country_id", using: :btree
    end

    create_table "country_translations", if_not_exists: true do |t|
      t.integer "country_id", null: false
      t.string "locale", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "name"
      t.string "region_name"
      t.index ["country_id"], name: "index_country_translations_on_country_id", using: :btree
      t.index ["locale"], name: "index_country_translations_on_locale", using: :btree
    end

    create_table "faq_translations", if_not_exists: true do |t|
      t.integer "faq_id", null: false
      t.string "locale", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "question"
      t.text "answer"
      t.index ["faq_id"], name: "index_faq_translations_on_faq_id", using: :btree
      t.index ["locale"], name: "index_faq_translations_on_locale", using: :btree
    end

    create_table "faqs", if_not_exists: true do |t|
      t.integer "position", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "image"
    end

    create_table "fmu_operators", if_not_exists: true do |t|
      t.integer "fmu_id", null: false
      t.integer "operator_id", null: false
      t.boolean "current", null: false
      t.date "start_date"
      t.date "end_date"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["fmu_id", "operator_id"], name: "index_fmu_operators_on_fmu_id_and_operator_id", using: :btree
      t.index ["operator_id", "fmu_id"], name: "index_fmu_operators_on_operator_id_and_fmu_id", using: :btree
    end

    create_table "fmu_translations", if_not_exists: true do |t|
      t.integer "fmu_id", null: false
      t.string "locale", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "name"
      t.index ["fmu_id"], name: "index_fmu_translations_on_fmu_id", using: :btree
      t.index ["locale"], name: "index_fmu_translations_on_locale", using: :btree
    end

    create_table "fmus", if_not_exists: true do |t|
      t.integer "country_id"
      t.jsonb "geojson"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "certification_fsc", default: false
      t.boolean "certification_pefc", default: false
      t.boolean "certification_olb", default: false
      t.boolean "certification_vlc"
      t.boolean "certification_vlo"
      t.boolean "certification_tltv"
      t.index ["country_id"], name: "index_fmus_on_country_id", using: :btree
    end

    create_table "government_translations", if_not_exists: true do |t|
      t.integer "government_id", null: false
      t.string "locale", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "government_entity"
      t.text "details"
      t.index ["government_id"], name: "index_government_translations_on_government_id", using: :btree
      t.index ["locale"], name: "index_government_translations_on_locale", using: :btree
    end

    create_table "governments", if_not_exists: true do |t|
      t.integer "country_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "is_active", default: true
      t.index ["country_id"], name: "index_governments_on_country_id", using: :btree
    end

    create_table "laws", if_not_exists: true do |t|
      t.text "written_infraction"
      t.text "infraction"
      t.text "sanctions"
      t.integer "min_fine"
      t.integer "max_fine"
      t.string "penal_servitude"
      t.text "other_penalties"
      t.text "apv"
      t.integer "subcategory_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "country_id"
      t.string "currency"
      t.index ["country_id"], name: "index_laws_on_country_id", using: :btree
      t.index ["subcategory_id"], name: "index_laws_on_subcategory_id", using: :btree
    end

    create_table "observation_documents", if_not_exists: true do |t|
      t.string "name"
      t.string "attachment"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "user_id"
      t.datetime "deleted_at"
      t.integer "observation_id"
      t.index ["deleted_at"], name: "index_observation_documents_on_deleted_at", using: :btree
      t.index ["name"], name: "index_observation_documents_on_name", using: :btree
      t.index ["observation_id"], name: "index_observation_documents_on_observation_id", using: :btree
      t.index ["user_id"], name: "index_observation_documents_on_user_id", using: :btree
    end

    create_table "observation_operators", if_not_exists: true do |t|
      t.integer "observation_id"
      t.integer "operator_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["observation_id"], name: "index_observation_operators_on_observation_id", using: :btree
      t.index ["operator_id"], name: "index_observation_operators_on_operator_id", using: :btree
    end

    create_table "observation_report_observers", if_not_exists: true do |t|
      t.integer "observation_report_id"
      t.integer "observer_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["observation_report_id", "observer_id"], name: "index_obs_rep_id_and_observer_id", using: :btree
      t.index ["observer_id", "observation_report_id"], name: "index_observer_id_and_obs_rep_id", using: :btree
    end

    create_table "observation_reports", if_not_exists: true do |t|
      t.string "title"
      t.datetime "publication_date"
      t.string "attachment"
      t.integer "user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.datetime "deleted_at"
      t.index ["deleted_at"], name: "index_observation_reports_on_deleted_at", using: :btree
      t.index ["title"], name: "index_observation_reports_on_title", using: :btree
      t.index ["user_id"], name: "index_observation_reports_on_user_id", using: :btree
    end

    create_table "observation_translations", if_not_exists: true do |t|
      t.integer "observation_id", null: false
      t.string "locale", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.text "details"
      t.string "evidence"
      t.text "concern_opinion"
      t.string "litigation_status"
      t.index ["locale"], name: "index_observation_translations_on_locale", using: :btree
      t.index ["observation_id"], name: "index_observation_translations_on_observation_id", using: :btree
    end

    create_table "observations", if_not_exists: true do |t|
      t.integer "severity_id"
      t.integer "observation_type", null: false
      t.integer "user_id"
      t.datetime "publication_date"
      t.integer "country_id"
      t.integer "operator_id"
      t.integer "government_id"
      t.string "pv"
      t.boolean "is_active", default: true
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.decimal "lat"
      t.decimal "lng"
      t.integer "fmu_id"
      t.integer "subcategory_id"
      t.integer "validation_status", default: 0, null: false
      t.integer "observation_report_id"
      t.text "actions_taken"
      t.integer "modified_user_id"
      t.integer "law_id"
      t.string "location_information"
      t.boolean "is_physical_place", default: true
      t.index ["country_id"], name: "index_observations_on_country_id", using: :btree
      t.index ["fmu_id"], name: "index_observations_on_fmu_id", using: :btree
      t.index ["government_id"], name: "index_observations_on_government_id", using: :btree
      t.index ["is_active"], name: "index_observations_on_is_active", using: :btree
      t.index ["law_id"], name: "index_observations_on_law_id", using: :btree
      t.index ["observation_report_id"], name: "index_observations_on_observation_report_id", using: :btree
      t.index ["observation_type"], name: "index_observations_on_observation_type", using: :btree
      t.index ["operator_id"], name: "index_observations_on_operator_id", using: :btree
      t.index ["severity_id"], name: "index_observations_on_severity_id", using: :btree
      t.index ["user_id"], name: "index_observations_on_user_id", using: :btree
      t.index ["validation_status"], name: "index_observations_on_validation_status", using: :btree
    end

    create_table "observer_observations", if_not_exists: true do |t|
      t.integer "observer_id"
      t.integer "observation_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["observation_id"], name: "index_observer_observations_on_observation_id", using: :btree
      t.index ["observer_id"], name: "index_observer_observations_on_observer_id", using: :btree
    end

    create_table "observer_translations", if_not_exists: true do |t|
      t.integer "observer_id", null: false
      t.string "locale", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "name"
      t.string "organization"
      t.index ["locale"], name: "index_observer_translations_on_locale", using: :btree
      t.index ["observer_id"], name: "index_observer_translations_on_observer_id", using: :btree
    end

    create_table "observers", if_not_exists: true do |t|
      t.string "observer_type", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "is_active", default: true
      t.string "logo"
      t.string "address"
      t.string "information_name"
      t.string "information_email"
      t.string "information_phone"
      t.string "data_name"
      t.string "data_email"
      t.string "data_phone"
      t.string "organization_type"
      t.index ["is_active"], name: "index_observers_on_is_active", using: :btree
    end

    create_table "operator_document_annexes", if_not_exists: true do |t|
      t.integer "operator_document_id"
      t.string "name"
      t.date "start_date"
      t.date "expire_date"
      t.date "deleted_at"
      t.integer "status"
      t.string "attachment"
      t.integer "uploaded_by"
      t.integer "user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["deleted_at"], name: "index_operator_document_annexes_on_deleted_at", using: :btree
      t.index ["operator_document_id"], name: "index_operator_document_annexes_on_operator_document_id", using: :btree
      t.index ["status"], name: "index_operator_document_annexes_on_status", using: :btree
      t.index ["user_id"], name: "index_operator_document_annexes_on_user_id", using: :btree
    end

    create_table "operator_documents", if_not_exists: true do |t|
      t.string "type"
      t.date "expire_date"
      t.date "start_date"
      t.integer "fmu_id"
      t.integer "required_operator_document_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "status"
      t.integer "operator_id"
      t.string "attachment"
      t.boolean "current"
      t.datetime "deleted_at"
      t.integer "uploaded_by"
      t.integer "user_id"
      t.text "reason"
      t.text "note"
      t.datetime "response_date"
      t.index ["current"], name: "index_operator_documents_on_current", using: :btree
      t.index ["deleted_at"], name: "index_operator_documents_on_deleted_at", using: :btree
      t.index ["expire_date"], name: "index_operator_documents_on_expire_date", using: :btree
      t.index ["fmu_id"], name: "index_operator_documents_on_fmu_id", using: :btree
      t.index ["operator_id"], name: "index_operator_documents_on_operator_id", using: :btree
      t.index ["required_operator_document_id"], name: "index_operator_documents_on_required_operator_document_id", using: :btree
      t.index ["start_date"], name: "index_operator_documents_on_start_date", using: :btree
      t.index ["status"], name: "index_operator_documents_on_status", using: :btree
      t.index ["type"], name: "index_operator_documents_on_type", using: :btree
    end

    create_table "operator_translations", if_not_exists: true do |t|
      t.integer "operator_id", null: false
      t.string "locale", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "name"
      t.text "details"
      t.index ["locale"], name: "index_operator_translations_on_locale", using: :btree
      t.index ["operator_id"], name: "index_operator_translations_on_operator_id", using: :btree
    end

    create_table "operators", if_not_exists: true do |t|
      t.string "operator_type"
      t.integer "country_id"
      t.string "concession"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "is_active", default: true
      t.string "logo"
      t.string "operator_id"
      t.float "percentage_valid_documents_all"
      t.float "percentage_valid_documents_country"
      t.float "percentage_valid_documents_fmu"
      t.float "score_absolute"
      t.integer "score"
      t.float "obs_per_visit"
      t.string "fa_id"
      t.string "address"
      t.string "website"
      t.integer "country_doc_rank"
      t.integer "country_operators"
      t.index ["country_id"], name: "index_operators_on_country_id", using: :btree
      t.index ["fa_id"], name: "index_operators_on_fa_id", using: :btree
      t.index ["is_active"], name: "index_operators_on_is_active", using: :btree
    end

    create_table "photos", if_not_exists: true do |t|
      t.string "name"
      t.string "attachment"
      t.integer "attacheable_id"
      t.string "attacheable_type"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "user_id"
      t.index ["attacheable_id", "attacheable_type"], name: "photos_attacheable_index", using: :btree
    end

    create_table "required_operator_document_group_translations", if_not_exists: true do |t|
      t.integer "required_operator_document_group_id", null: false
      t.string "locale", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "name"
      t.index ["locale"], name: "index_required_operator_document_group_translations_on_locale", using: :btree
      t.index ["required_operator_document_group_id"], name: "index_64b55c0cec158f1717cc5d775ae87c7a48f1cc59", using: :btree
    end

    create_table "required_operator_document_groups", if_not_exists: true do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "position"
    end

    create_table "required_operator_document_translations", if_not_exists: true do |t|
      t.integer "required_operator_document_id", null: false
      t.string "locale", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.text "explanation"
      t.index ["locale"], name: "index_required_operator_document_translations_on_locale", using: :btree
      t.index ["required_operator_document_id"], name: "index_eed74ed5a0934f32c4b075e5beee98f1ebf34d19", using: :btree
    end

    create_table "required_operator_documents", if_not_exists: true do |t|
      t.string "type"
      t.integer "required_operator_document_group_id"
      t.string "name"
      t.integer "country_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "valid_period"
      t.datetime "deleted_at"
      t.index ["deleted_at"], name: "index_required_operator_documents_on_deleted_at", using: :btree
      t.index ["required_operator_document_group_id"], name: "index_req_op_doc_group_id", using: :btree
      t.index ["type"], name: "index_required_operator_documents_on_type", using: :btree
    end

    create_table "sawmills", if_not_exists: true do |t|
      t.string "name"
      t.float "lat"
      t.float "lng"
      t.boolean "is_active", default: true, null: false
      t.integer "operator_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.jsonb "geojson"
    end

    create_table "severities", if_not_exists: true do |t|
      t.integer "level"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "subcategory_id"
      t.index ["level", "subcategory_id"], name: "index_severities_on_level_and_subcategory_id", using: :btree
      t.index ["subcategory_id", "level"], name: "index_severities_on_subcategory_id_and_level", using: :btree
    end

    create_table "severity_translations", if_not_exists: true do |t|
      t.integer "severity_id", null: false
      t.string "locale", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.text "details"
      t.index ["locale"], name: "index_severity_translations_on_locale", using: :btree
      t.index ["severity_id"], name: "index_severity_translations_on_severity_id", using: :btree
    end

    create_table "species", if_not_exists: true do |t|
      t.string "name"
      t.string "species_class"
      t.string "sub_species"
      t.string "species_family"
      t.string "species_kingdom"
      t.string "scientific_name"
      t.string "cites_status"
      t.integer "cites_id"
      t.integer "iucn_status"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "species_countries", if_not_exists: true do |t|
      t.integer "country_id"
      t.integer "species_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["country_id"], name: "index_species_countries_on_country_id", using: :btree
      t.index ["species_id"], name: "index_species_countries_on_species_id", using: :btree
    end

    create_table "species_observations", if_not_exists: true do |t|
      t.integer "observation_id"
      t.integer "species_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["observation_id"], name: "index_species_observations_on_observation_id", using: :btree
      t.index ["species_id"], name: "index_species_observations_on_species_id", using: :btree
    end

    create_table "species_translations", if_not_exists: true do |t|
      t.integer "species_id", null: false
      t.string "locale", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "common_name"
      t.index ["locale"], name: "index_species_translations_on_locale", using: :btree
      t.index ["species_id"], name: "index_species_translations_on_species_id", using: :btree
    end

    create_table "subcategories", if_not_exists: true do |t|
      t.integer "category_id"
      t.integer "subcategory_type"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "location_required", default: true
      t.index ["category_id"], name: "index_subcategories_on_category_id", using: :btree
      t.index ["subcategory_type"], name: "index_subcategories_on_subcategory_type", using: :btree
    end

    create_table "subcategory_translations", if_not_exists: true do |t|
      t.integer "subcategory_id", null: false
      t.string "locale", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "name"
      t.text "details"
      t.index ["locale"], name: "index_subcategory_translations_on_locale", using: :btree
      t.index ["subcategory_id"], name: "index_subcategory_translations_on_subcategory_id", using: :btree
    end

    create_table "user_permissions", if_not_exists: true do |t|
      t.integer "user_id"
      t.integer "user_role", default: 0, null: false
      t.jsonb "permissions", default: {}
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "users", if_not_exists: true do |t|
      t.string "email"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "nickname"
      t.string "name"
      t.string "institution"
      t.string "web_url"
      t.boolean "is_active", default: true
      t.datetime "deactivated_at"
      t.integer "permissions_request"
      t.datetime "permissions_accepted"
      t.integer "country_id"
      t.string "reset_password_token"
      t.datetime "reset_password_sent_at"
      t.integer "sign_in_count", default: 0, null: false
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.inet "current_sign_in_ip"
      t.inet "last_sign_in_ip"
      t.string "encrypted_password", default: "", null: false
      t.datetime "remember_created_at"
      t.integer "observer_id"
      t.integer "operator_id"
      t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
      t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    end

    create_table "tutorials", if_not_exists: true do |t|
      t.integer "position"
      t.string "name", null: false
      t.text "description"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "uploaded_documents", if_not_exists: true do |t|
      t.string "name"
      t.string "author"
      t.string "caption"
      t.string "file"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    add_foreign_key "api_keys", "users"
    add_foreign_key "comments", "users"
    add_foreign_key "laws", "countries"
    add_foreign_key "laws", "subcategories"
    add_foreign_key "observation_documents", "observations"
    add_foreign_key "observation_documents", "users"
    add_foreign_key "observation_operators", "observations"
    add_foreign_key "observation_operators", "operators"
    add_foreign_key "observation_report_observers", "observation_reports"
    add_foreign_key "observation_report_observers", "observers"
    add_foreign_key "observation_reports", "users"
    add_foreign_key "observations", "countries"
    add_foreign_key "observations", "fmus"
    add_foreign_key "observations", "governments"
    add_foreign_key "observations", "laws"
    add_foreign_key "observations", "observation_reports"
    add_foreign_key "observations", "operators"
    add_foreign_key "observations", "users", column: "modified_user_id"
    add_foreign_key "operator_documents", "fmus"
    add_foreign_key "operator_documents", "operators"
    add_foreign_key "operator_documents", "required_operator_documents"
    add_foreign_key "photos", "users"
    add_foreign_key "required_operator_documents", "countries"
    add_foreign_key "required_operator_documents", "required_operator_document_groups"
    add_foreign_key "sawmills", "operators"
    add_foreign_key "severities", "subcategories"
    add_foreign_key "subcategories", "categories"
    add_foreign_key "user_permissions", "users"
    add_foreign_key "users", "countries"
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_07_18_101902) do
  create_schema "tiger"
  create_schema "tiger_data"
  create_schema "topology"

  # These are extensions that must be enabled in order to support this database
  enable_extension "address_standardizer"
  enable_extension "address_standardizer_data_us"
  enable_extension "citext"
  enable_extension "fuzzystrmatch"
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "postgis_tiger_geocoder"
  enable_extension "postgis_topology"

  create_table "about_page_entries", id: :serial, force: :cascade do |t|
    t.integer "position", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "code"
    t.index ["position"], name: "index_about_page_entries_on_position"
  end

  create_table "about_page_entry_translations", id: :serial, force: :cascade do |t|
    t.integer "about_page_entry_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "title"
    t.text "body"
    t.index ["about_page_entry_id"], name: "index_about_page_entry_translations_on_about_page_entry_id"
    t.index ["locale"], name: "index_about_page_entry_translations_on_locale"
  end

  create_table "active_admin_comments", id: :serial, force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.integer "resource_id"
    t.string "author_type"
    t.integer "author_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "annex_documents", id: :serial, force: :cascade do |t|
    t.string "documentable_type", null: false
    t.integer "documentable_id", null: false
    t.integer "operator_document_annex_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["documentable_id"], name: "index_annex_documents_on_documentable_id"
    t.index ["documentable_type"], name: "index_annex_documents_on_documentable_type"
    t.index ["operator_document_annex_id"], name: "index_annex_documents_on_operator_document_annex_id"
  end

  create_table "api_keys", id: :serial, force: :cascade do |t|
    t.string "access_token"
    t.datetime "expires_at", precision: nil
    t.integer "user_id"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["access_token"], name: "index_api_keys_on_access_token", unique: true
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "categories", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "category_type"
  end

  create_table "category_translations", id: :serial, force: :cascade do |t|
    t.integer "category_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.index ["category_id"], name: "index_category_translations_on_category_id"
    t.index ["locale"], name: "index_category_translations_on_locale"
    t.index ["name", "category_id"], name: "index_category_translations_on_name_and_category_id"
  end

  create_table "contributor_translations", id: :serial, force: :cascade do |t|
    t.integer "contributor_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name", null: false
    t.text "description"
    t.index ["contributor_id"], name: "index_contributor_translations_on_contributor_id"
    t.index ["locale"], name: "index_contributor_translations_on_locale"
  end

  create_table "contributors", id: :serial, force: :cascade do |t|
    t.string "website"
    t.string "logo"
    t.integer "priority"
    t.integer "category"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "type", default: "Partner"
    t.index ["type"], name: "index_contributors_on_type"
  end

  create_table "countries", id: :serial, force: :cascade do |t|
    t.string "iso"
    t.string "region_iso"
    t.jsonb "country_centroid"
    t.jsonb "region_centroid"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_active", default: false, null: false
    t.index ["is_active"], name: "index_countries_on_is_active"
    t.index ["iso"], name: "index_countries_on_iso"
  end

  create_table "countries_observers", id: false, force: :cascade do |t|
    t.integer "country_id", null: false
    t.integer "observer_id", null: false
    t.index ["country_id", "observer_id"], name: "index_countries_observers_on_country_id_and_observer_id"
    t.index ["country_id", "observer_id"], name: "index_unique_country_observer", unique: true
    t.index ["observer_id", "country_id"], name: "index_countries_observers_on_observer_id_and_country_id"
  end

  create_table "country_link_translations", id: :serial, force: :cascade do |t|
    t.integer "country_link_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.text "description"
    t.index ["country_link_id"], name: "index_country_link_translations_on_country_link_id"
    t.index ["locale"], name: "index_country_link_translations_on_locale"
  end

  create_table "country_links", id: :serial, force: :cascade do |t|
    t.string "url"
    t.boolean "active", default: true, null: false
    t.integer "position"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "country_id"
    t.index ["country_id"], name: "index_country_links_on_country_id"
  end

  create_table "country_responsible_admins", force: :cascade do |t|
    t.bigint "country_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id", "user_id"], name: "index_country_responsible_admins_on_country_id_and_user_id", unique: true
    t.index ["country_id"], name: "index_country_responsible_admins_on_country_id"
    t.index ["user_id"], name: "index_country_responsible_admins_on_user_id"
  end

  create_table "country_translations", id: :serial, force: :cascade do |t|
    t.integer "country_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.string "region_name"
    t.text "overview"
    t.text "vpa_overview"
    t.index ["country_id"], name: "index_country_translations_on_country_id"
    t.index ["locale"], name: "index_country_translations_on_locale"
    t.index ["name", "country_id"], name: "index_country_translations_on_name_and_country_id"
  end

  create_table "country_vpa_translations", id: :serial, force: :cascade do |t|
    t.integer "country_vpa_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.text "description"
    t.index ["country_vpa_id"], name: "index_country_vpa_translations_on_country_vpa_id"
    t.index ["locale"], name: "index_country_vpa_translations_on_locale"
  end

  create_table "country_vpas", id: :serial, force: :cascade do |t|
    t.string "url"
    t.boolean "active", default: true, null: false
    t.integer "position"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "country_id"
    t.index ["country_id"], name: "index_country_vpas_on_country_id"
  end

  create_table "document_files", id: :serial, force: :cascade do |t|
    t.string "attachment"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "faq_translations", id: :serial, force: :cascade do |t|
    t.integer "faq_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "question"
    t.text "answer"
    t.index ["faq_id"], name: "index_faq_translations_on_faq_id"
    t.index ["locale"], name: "index_faq_translations_on_locale"
  end

  create_table "faqs", id: :serial, force: :cascade do |t|
    t.integer "position", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "image"
    t.index ["position"], name: "index_faqs_on_position", unique: true
  end

  create_table "fmu_operators", id: :serial, force: :cascade do |t|
    t.integer "fmu_id", null: false
    t.integer "operator_id", null: false
    t.boolean "current", default: false, null: false
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_fmu_operators_on_deleted_at"
    t.index ["fmu_id", "operator_id"], name: "index_fmu_operators_on_fmu_id_and_operator_id"
    t.index ["operator_id", "fmu_id"], name: "index_fmu_operators_on_operator_id_and_fmu_id"
  end

  create_table "fmus", id: :serial, force: :cascade do |t|
    t.integer "country_id"
    t.jsonb "geojson"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "certification_fsc", default: false, null: false
    t.boolean "certification_pefc", default: false, null: false
    t.boolean "certification_olb", default: false, null: false
    t.boolean "certification_pafc", default: false, null: false
    t.boolean "certification_fsc_cw", default: false, null: false
    t.boolean "certification_tlv", default: false, null: false
    t.integer "forest_type", default: 0, null: false
    t.geometry "geometry", limit: {:srid=>0, :type=>"geometry"}
    t.datetime "deleted_at", precision: nil
    t.boolean "certification_ls", default: false, null: false
    t.string "name", null: false
    t.index ["country_id"], name: "index_fmus_on_country_id"
    t.index ["deleted_at"], name: "index_fmus_on_deleted_at"
    t.index ["forest_type"], name: "index_fmus_on_forest_type"
  end

  create_table "gov_documents", id: :serial, force: :cascade do |t|
    t.integer "status", null: false
    t.date "start_date"
    t.date "expire_date"
    t.integer "uploaded_by"
    t.string "link"
    t.string "value"
    t.string "units"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "required_gov_document_id", null: false
    t.integer "country_id", null: false
    t.integer "user_id"
    t.string "attachment"
    t.index ["country_id"], name: "index_gov_documents_on_country_id"
    t.index ["required_gov_document_id"], name: "index_gov_documents_on_required_gov_document_id"
    t.index ["user_id"], name: "index_gov_documents_on_user_id"
  end

  create_table "government_translations", id: :serial, force: :cascade do |t|
    t.integer "government_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "government_entity"
    t.text "details"
    t.index ["government_entity", "government_id"], name: "index_gvt_t_on_government_entity_and_government_id"
    t.index ["government_id"], name: "index_government_translations_on_government_id"
    t.index ["locale"], name: "index_government_translations_on_locale"
  end

  create_table "governments", id: :serial, force: :cascade do |t|
    t.integer "country_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_active", default: true, null: false
    t.index ["country_id"], name: "index_governments_on_country_id"
  end

  create_table "governments_observations", id: :serial, force: :cascade do |t|
    t.integer "government_id"
    t.integer "observation_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_governments_observations_on_deleted_at"
    t.index ["government_id", "observation_id"], name: "governments_observations_association_index", unique: true
    t.index ["government_id"], name: "index_governments_observations_on_government_id"
    t.index ["observation_id", "government_id"], name: "observations_governments_association_index", unique: true
    t.index ["observation_id"], name: "index_governments_observations_on_observation_id"
  end

  create_table "holdings", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_holdings_on_name"
  end

  create_table "how_to_translations", id: :serial, force: :cascade do |t|
    t.integer "how_to_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.text "description"
    t.index ["how_to_id"], name: "index_how_to_translations_on_how_to_id"
    t.index ["locale"], name: "index_how_to_translations_on_locale"
  end

  create_table "how_tos", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "laws", id: :serial, force: :cascade do |t|
    t.text "written_infraction"
    t.text "infraction"
    t.text "sanctions"
    t.integer "min_fine"
    t.integer "max_fine"
    t.string "penal_servitude"
    t.text "other_penalties"
    t.text "apv"
    t.integer "subcategory_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "country_id"
    t.string "currency"
    t.index ["country_id"], name: "index_laws_on_country_id"
    t.index ["max_fine"], name: "index_laws_on_max_fine"
    t.index ["min_fine"], name: "index_laws_on_min_fine"
    t.index ["subcategory_id"], name: "index_laws_on_subcategory_id"
  end

  create_table "newsletter_translations", force: :cascade do |t|
    t.bigint "newsletter_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title", null: false
    t.text "short_description", null: false
    t.string "title_translated_from"
    t.string "short_description_translated_from"
    t.index ["locale"], name: "index_newsletter_translations_on_locale"
    t.index ["newsletter_id"], name: "index_newsletter_translations_on_newsletter_id"
  end

  create_table "newsletters", force: :cascade do |t|
    t.date "date", null: false
    t.string "attachment", null: false
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notification_groups", id: :serial, force: :cascade do |t|
    t.integer "days", null: false
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.datetime "last_displayed_at", precision: nil
    t.datetime "dismissed_at", precision: nil
    t.datetime "solved_at", precision: nil
    t.integer "operator_document_id", null: false
    t.integer "user_id", null: false
    t.integer "notification_group_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["dismissed_at"], name: "index_notifications_on_dismissed_at"
    t.index ["last_displayed_at"], name: "index_notifications_on_last_displayed_at"
    t.index ["notification_group_id"], name: "index_notifications_on_notification_group_id"
    t.index ["operator_document_id"], name: "index_notifications_on_operator_document_id"
    t.index ["solved_at"], name: "index_notifications_on_solved_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "observation_documents", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "attachment"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "document_type", default: 0, null: false
    t.bigint "observation_report_id"
    t.index ["deleted_at"], name: "index_observation_documents_on_deleted_at"
    t.index ["name"], name: "index_observation_documents_on_name"
    t.index ["observation_report_id"], name: "index_observation_documents_on_observation_report_id"
  end

  create_table "observation_documents_observations", force: :cascade do |t|
    t.bigint "observation_document_id", null: false
    t.bigint "observation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_observation_documents_observations_on_deleted_at"
    t.index ["observation_document_id", "observation_id"], name: "observation_documents_observations_double_index", unique: true
    t.index ["observation_document_id"], name: "observation_documents_observations_doc_index"
    t.index ["observation_id"], name: "observation_documents_observations_obs_index"
  end

  create_table "observation_histories", id: :serial, force: :cascade do |t|
    t.integer "validation_status"
    t.integer "observation_type"
    t.integer "location_accuracy"
    t.integer "severity_level"
    t.integer "fmu_forest_type"
    t.datetime "observation_updated_at", precision: nil
    t.datetime "observation_created_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "observation_id"
    t.integer "fmu_id"
    t.integer "category_id"
    t.integer "subcategory_id"
    t.integer "country_id"
    t.integer "operator_id"
    t.boolean "hidden", default: false, null: false
    t.boolean "is_active", default: false, null: false
    t.index ["category_id"], name: "index_observation_histories_on_category_id"
    t.index ["country_id"], name: "index_observation_histories_on_country_id"
    t.index ["fmu_forest_type"], name: "index_observation_histories_on_fmu_forest_type"
    t.index ["fmu_id"], name: "index_observation_histories_on_fmu_id"
    t.index ["hidden"], name: "index_observation_histories_on_hidden"
    t.index ["is_active"], name: "index_observation_histories_on_is_active"
    t.index ["observation_id"], name: "index_observation_histories_on_observation_id"
    t.index ["operator_id"], name: "index_observation_histories_on_operator_id"
    t.index ["severity_level"], name: "index_observation_histories_on_severity_level"
    t.index ["subcategory_id"], name: "index_observation_histories_on_subcategory_id"
    t.index ["validation_status"], name: "index_observation_histories_on_validation_status"
  end

  create_table "observation_operators", id: :serial, force: :cascade do |t|
    t.integer "observation_id"
    t.integer "operator_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_observation_operators_on_deleted_at"
    t.index ["observation_id"], name: "index_observation_operators_on_observation_id"
    t.index ["operator_id"], name: "index_observation_operators_on_operator_id"
  end

  create_table "observation_report_observers", id: :serial, force: :cascade do |t|
    t.integer "observation_report_id"
    t.integer "observer_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["observation_report_id", "observer_id"], name: "index_obs_rep_id_and_observer_id"
    t.index ["observer_id", "observation_report_id"], name: "index_observer_id_and_obs_rep_id"
  end

  create_table "observation_report_statistics", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.integer "country_id"
    t.integer "observer_id"
    t.integer "total_count", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["country_id"], name: "index_observation_report_statistics_on_country_id"
    t.index ["date", "country_id", "observer_id"], name: "index_observation_report_statistics_on_filters", unique: true
    t.index ["date"], name: "index_observation_report_statistics_on_date"
    t.index ["observer_id"], name: "index_observation_report_statistics_on_observer_id"
  end

  create_table "observation_reports", id: :serial, force: :cascade do |t|
    t.string "title"
    t.datetime "publication_date", precision: nil
    t.string "attachment"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_observation_reports_on_deleted_at"
    t.index ["title"], name: "index_observation_reports_on_title"
    t.index ["user_id"], name: "index_observation_reports_on_user_id"
  end

  create_table "observation_statistics", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.integer "country_id"
    t.integer "operator_id"
    t.integer "subcategory_id"
    t.integer "category_id"
    t.integer "fmu_id"
    t.integer "severity_level"
    t.integer "validation_status"
    t.integer "fmu_forest_type"
    t.integer "total_count", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "hidden", default: false, null: false
    t.boolean "is_active", default: false, null: false
    t.integer "observation_type"
    t.index ["category_id"], name: "index_observation_statistics_on_category_id"
    t.index ["country_id"], name: "index_observation_statistics_on_country_id"
    t.index ["date"], name: "index_observation_statistics_on_date"
    t.index ["fmu_id"], name: "index_observation_statistics_on_fmu_id"
    t.index ["operator_id"], name: "index_observation_statistics_on_operator_id"
    t.index ["subcategory_id"], name: "index_observation_statistics_on_subcategory_id"
  end

  create_table "observation_translations", id: :serial, force: :cascade do |t|
    t.integer "observation_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "details"
    t.text "concern_opinion"
    t.string "litigation_status"
    t.datetime "deleted_at", precision: nil
    t.string "details_translated_from"
    t.string "concern_opinion_translated_from"
    t.string "litigation_status_translated_from"
    t.index ["deleted_at"], name: "index_observation_translations_on_deleted_at"
    t.index ["locale"], name: "index_observation_translations_on_locale"
    t.index ["observation_id"], name: "index_observation_translations_on_observation_id"
  end

  create_table "observations", id: :serial, force: :cascade do |t|
    t.integer "severity_id"
    t.integer "observation_type", null: false
    t.integer "user_id"
    t.datetime "publication_date", precision: nil
    t.integer "country_id"
    t.integer "operator_id"
    t.string "pv"
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.boolean "is_physical_place", default: true, null: false
    t.integer "evidence_type"
    t.integer "location_accuracy"
    t.string "evidence_on_report"
    t.boolean "hidden", default: false, null: false
    t.text "admin_comment"
    t.text "monitor_comment"
    t.datetime "deleted_at", precision: nil
    t.string "locale"
    t.index ["country_id"], name: "index_observations_on_country_id"
    t.index ["created_at"], name: "index_observations_on_created_at"
    t.index ["deleted_at"], name: "index_observations_on_deleted_at"
    t.index ["evidence_type"], name: "index_observations_on_evidence_type"
    t.index ["fmu_id"], name: "index_observations_on_fmu_id"
    t.index ["hidden"], name: "index_observations_on_hidden"
    t.index ["is_active"], name: "index_observations_on_is_active"
    t.index ["is_physical_place"], name: "index_observations_on_is_physical_place"
    t.index ["law_id"], name: "index_observations_on_law_id"
    t.index ["location_accuracy"], name: "index_observations_on_location_accuracy"
    t.index ["observation_report_id"], name: "index_observations_on_observation_report_id"
    t.index ["observation_type"], name: "index_observations_on_observation_type"
    t.index ["operator_id"], name: "index_observations_on_operator_id"
    t.index ["publication_date"], name: "index_observations_on_publication_date"
    t.index ["severity_id"], name: "index_observations_on_severity_id"
    t.index ["updated_at"], name: "index_observations_on_updated_at"
    t.index ["user_id"], name: "index_observations_on_user_id"
    t.index ["validation_status"], name: "index_observations_on_validation_status"
  end

  create_table "observer_managers", force: :cascade do |t|
    t.bigint "observer_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["observer_id"], name: "index_observer_managers_on_observer_id"
    t.index ["user_id", "observer_id"], name: "index_observer_managers_on_user_id_and_observer_id", unique: true
    t.index ["user_id"], name: "index_observer_managers_on_user_id"
  end

  create_table "observer_observations", id: :serial, force: :cascade do |t|
    t.integer "observer_id"
    t.integer "observation_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_observer_observations_on_deleted_at"
    t.index ["observation_id"], name: "index_observer_observations_on_observation_id"
    t.index ["observer_id"], name: "index_observer_observations_on_observer_id"
  end

  create_table "observers", id: :serial, force: :cascade do |t|
    t.string "observer_type", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_active", default: true, null: false
    t.string "logo"
    t.string "address"
    t.string "information_name"
    t.string "information_email"
    t.string "information_phone"
    t.string "data_name"
    t.string "data_email"
    t.string "data_phone"
    t.string "organization_type"
    t.boolean "public_info", default: false, null: false
    t.integer "responsible_admin_id"
    t.string "name", null: false
    t.bigint "responsible_qc1_id"
    t.bigint "responsible_qc2_id"
    t.index ["is_active"], name: "index_observers_on_is_active"
    t.index ["responsible_qc1_id"], name: "index_observers_on_responsible_qc1_id"
    t.index ["responsible_qc2_id"], name: "index_observers_on_responsible_qc2_id"
  end

  create_table "operator_document_annexes", id: :serial, force: :cascade do |t|
    t.string "name"
    t.date "start_date"
    t.date "expire_date"
    t.date "deleted_at"
    t.integer "status"
    t.string "attachment"
    t.integer "uploaded_by"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "public", default: true, null: false
    t.index ["deleted_at"], name: "index_operator_document_annexes_on_deleted_at"
    t.index ["public"], name: "index_operator_document_annexes_on_public"
    t.index ["status"], name: "index_operator_document_annexes_on_status"
    t.index ["user_id"], name: "index_operator_document_annexes_on_user_id"
  end

  create_table "operator_document_histories", id: :serial, force: :cascade do |t|
    t.string "type"
    t.date "expire_date"
    t.date "start_date"
    t.integer "status"
    t.integer "uploaded_by"
    t.text "reason"
    t.text "note"
    t.datetime "response_date", precision: nil
    t.boolean "public", default: false, null: false
    t.integer "source"
    t.string "source_info"
    t.integer "fmu_id"
    t.integer "document_file_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "operator_document_id"
    t.integer "operator_id"
    t.integer "user_id"
    t.integer "required_operator_document_id"
    t.datetime "deleted_at", precision: nil
    t.datetime "operator_document_updated_at", precision: nil, null: false
    t.datetime "operator_document_created_at", precision: nil, null: false
    t.text "admin_comment"
    t.index ["deleted_at"], name: "index_operator_document_histories_on_deleted_at"
    t.index ["document_file_id"], name: "index_operator_document_histories_on_document_file_id"
    t.index ["expire_date"], name: "index_operator_document_histories_on_expire_date"
    t.index ["fmu_id"], name: "index_operator_document_histories_on_fmu_id"
    t.index ["operator_document_id"], name: "index_operator_document_histories_on_operator_document_id"
    t.index ["operator_id"], name: "index_operator_document_histories_on_operator_id"
    t.index ["public"], name: "index_operator_document_histories_on_public"
    t.index ["required_operator_document_id"], name: "index_odh_on_rod_id_id"
    t.index ["response_date"], name: "index_operator_document_histories_on_response_date"
    t.index ["source"], name: "index_operator_document_histories_on_source"
    t.index ["status"], name: "index_operator_document_histories_on_status"
    t.index ["type"], name: "index_operator_document_histories_on_type"
    t.index ["user_id"], name: "index_operator_document_histories_on_user_id"
  end

  create_table "operator_document_statistics", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.integer "country_id"
    t.integer "required_operator_document_group_id"
    t.integer "fmu_forest_type"
    t.string "document_type"
    t.integer "valid_count", default: 0
    t.integer "invalid_count", default: 0
    t.integer "pending_count", default: 0
    t.integer "not_provided_count", default: 0
    t.integer "not_required_count", default: 0
    t.integer "expired_count", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["country_id"], name: "index_operator_document_statistics_on_country_id"
    t.index ["date", "country_id", "required_operator_document_group_id", "fmu_forest_type", "document_type"], name: "index_operator_document_statistics_on_filters", unique: true
    t.index ["date"], name: "index_operator_document_statistics_on_date"
    t.index ["required_operator_document_group_id"], name: "index_operator_document_statistics_rodg"
  end

  create_table "operator_documents", id: :serial, force: :cascade do |t|
    t.string "type"
    t.date "expire_date"
    t.date "start_date"
    t.integer "fmu_id"
    t.integer "required_operator_document_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "status"
    t.integer "operator_id"
    t.datetime "deleted_at", precision: nil
    t.integer "uploaded_by"
    t.integer "user_id"
    t.text "reason"
    t.text "note"
    t.datetime "response_date", precision: nil
    t.boolean "public", default: true, null: false
    t.integer "source", default: 1
    t.string "source_info"
    t.integer "document_file_id"
    t.text "admin_comment"
    t.index ["deleted_at"], name: "index_operator_documents_on_deleted_at"
    t.index ["document_file_id"], name: "index_operator_documents_on_document_file_id"
    t.index ["expire_date"], name: "index_operator_documents_on_expire_date"
    t.index ["fmu_id"], name: "index_operator_documents_on_fmu_id"
    t.index ["operator_id"], name: "index_operator_documents_on_operator_id"
    t.index ["public"], name: "index_operator_documents_on_public"
    t.index ["required_operator_document_id"], name: "index_operator_documents_on_required_operator_document_id"
    t.index ["source"], name: "index_operator_documents_on_source"
    t.index ["start_date"], name: "index_operator_documents_on_start_date"
    t.index ["status"], name: "index_operator_documents_on_status"
    t.index ["type"], name: "index_operator_documents_on_type"
  end

  create_table "operators", id: :serial, force: :cascade do |t|
    t.string "operator_type"
    t.integer "country_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_active", default: true, null: false
    t.string "logo"
    t.string "operator_id"
    t.string "fa_id"
    t.string "address"
    t.string "website"
    t.boolean "approved", default: true, null: false
    t.integer "holding_id"
    t.integer "country_doc_rank"
    t.integer "country_operators"
    t.string "name"
    t.string "details"
    t.string "slug"
    t.index "btrim(lower((name)::text))", name: "index_operators_on_btrim_lower_name", unique: true
    t.index ["approved"], name: "index_operators_on_approved"
    t.index ["country_id"], name: "index_operators_on_country_id"
    t.index ["fa_id"], name: "index_operators_on_fa_id"
    t.index ["is_active"], name: "index_operators_on_is_active"
    t.index ["slug"], name: "index_operators_on_slug", unique: true
  end

  create_table "page_translations", force: :cascade do |t|
    t.bigint "page_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title"
    t.text "body"
    t.index ["locale"], name: "index_page_translations_on_locale"
    t.index ["page_id"], name: "index_page_translations_on_page_id"
  end

  create_table "pages", force: :cascade do |t|
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "available_in_languages", array: true
    t.index ["slug"], name: "index_pages_on_slug", unique: true
  end

  create_table "protected_areas", force: :cascade do |t|
    t.bigint "country_id", null: false
    t.string "name", null: false
    t.string "wdpa_pid", null: false
    t.jsonb "geojson", null: false
    t.geometry "geometry", limit: {:srid=>0, :type=>"geometry"}
    t.virtual "centroid", type: :geometry, limit: {:srid=>0, :type=>"st_point"}, as: "st_centroid(geometry)", stored: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_protected_areas_on_country_id"
  end

  create_table "required_gov_document_group_translations", id: :serial, force: :cascade do |t|
    t.integer "required_gov_document_group_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_required_gov_document_group_translations_on_deleted_at"
    t.index ["locale"], name: "index_required_gov_document_group_translations_on_locale"
    t.index ["required_gov_document_group_id"], name: "index_d5783e31f1865cb8918d628281b44e29621b4216"
  end

  create_table "required_gov_document_groups", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.bigint "parent_id"
    t.index ["deleted_at"], name: "index_required_gov_document_groups_on_deleted_at"
    t.index ["parent_id"], name: "index_required_gov_document_groups_on_parent_id"
  end

  create_table "required_gov_document_translations", id: :serial, force: :cascade do |t|
    t.integer "required_gov_document_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "explanation"
    t.datetime "deleted_at", precision: nil
    t.string "name"
    t.index ["deleted_at"], name: "index_required_gov_document_translations_on_deleted_at"
    t.index ["locale"], name: "index_required_gov_document_translations_on_locale"
    t.index ["required_gov_document_id"], name: "index_759a54fdd00cf06c291ffc4857fb904934dd47b9"
  end

  create_table "required_gov_documents", id: :serial, force: :cascade do |t|
    t.integer "document_type", null: false
    t.integer "valid_period"
    t.datetime "deleted_at", precision: nil
    t.integer "required_gov_document_group_id"
    t.integer "country_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "position"
    t.index ["country_id", "required_gov_document_group_id", "position"], name: "index_rgd_on_country_id_and_rgdg_id_and_position"
    t.index ["country_id"], name: "index_required_gov_documents_on_country_id"
    t.index ["deleted_at"], name: "index_required_gov_documents_on_deleted_at"
    t.index ["document_type"], name: "index_required_gov_documents_on_document_type"
    t.index ["required_gov_document_group_id"], name: "index_required_gov_documents_on_required_gov_document_group_id"
  end

  create_table "required_operator_document_group_translations", id: :serial, force: :cascade do |t|
    t.integer "required_operator_document_group_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.index ["locale"], name: "index_required_operator_document_group_translations_on_locale"
    t.index ["required_operator_document_group_id"], name: "index_64b55c0cec158f1717cc5d775ae87c7a48f1cc59"
  end

  create_table "required_operator_document_groups", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "position"
  end

  create_table "required_operator_document_translations", id: :serial, force: :cascade do |t|
    t.integer "required_operator_document_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "explanation"
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_required_operator_document_translations_on_deleted_at"
    t.index ["locale"], name: "index_required_operator_document_translations_on_locale"
    t.index ["required_operator_document_id"], name: "index_eed74ed5a0934f32c4b075e5beee98f1ebf34d19"
  end

  create_table "required_operator_documents", id: :serial, force: :cascade do |t|
    t.string "type"
    t.integer "required_operator_document_group_id"
    t.string "name"
    t.integer "country_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "valid_period"
    t.datetime "deleted_at", precision: nil
    t.integer "forest_types", default: [], array: true
    t.boolean "contract_signature", default: false, null: false
    t.integer "position"
    t.index ["contract_signature"], name: "index_required_operator_documents_on_contract_signature"
    t.index ["country_id", "required_operator_document_group_id", "position"], name: "index_rod_on_country_id_and_rodg_id_and_position"
    t.index ["deleted_at"], name: "index_required_operator_documents_on_deleted_at"
    t.index ["forest_types"], name: "index_required_operator_documents_on_forest_types"
    t.index ["required_operator_document_group_id"], name: "index_req_op_doc_group_id"
    t.index ["type"], name: "index_required_operator_documents_on_type"
  end

  create_table "sawmills", id: :serial, force: :cascade do |t|
    t.string "name"
    t.float "lat"
    t.float "lng"
    t.boolean "is_active", default: true, null: false
    t.integer "operator_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "geojson"
  end

  create_table "score_operator_documents", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.boolean "current", default: true, null: false
    t.float "all"
    t.float "country"
    t.float "fmu"
    t.jsonb "summary_public"
    t.jsonb "summary_private"
    t.integer "total"
    t.integer "operator_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["current"], name: "index_score_operator_documents_on_current"
    t.index ["date"], name: "index_score_operator_documents_on_date"
    t.index ["operator_id", "current"], name: "index_score_operator_documents_on_operator_id_and_current", unique: true, where: "current"
    t.index ["operator_id"], name: "index_score_operator_documents_on_operator_id"
  end

  create_table "score_operator_observations", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.boolean "current", default: true, null: false
    t.float "score"
    t.float "obs_per_visit"
    t.integer "operator_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["current", "operator_id"], name: "index_score_operator_observations_on_current_and_operator_id"
    t.index ["current"], name: "index_score_operator_observations_on_current"
    t.index ["date"], name: "index_score_operator_observations_on_date"
    t.index ["operator_id", "current"], name: "index_score_operator_observations_on_operator_id_and_current", unique: true, where: "current"
    t.index ["operator_id"], name: "index_score_operator_observations_on_operator_id"
  end

  create_table "severities", id: :serial, force: :cascade do |t|
    t.integer "level"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "subcategory_id"
    t.index ["level", "id"], name: "index_severities_on_level_and_id"
    t.index ["level", "subcategory_id"], name: "index_severities_on_level_and_subcategory_id", unique: true
    t.index ["level"], name: "index_severities_on_level"
  end

  create_table "severity_translations", id: :serial, force: :cascade do |t|
    t.integer "severity_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "details"
    t.index ["locale"], name: "index_severity_translations_on_locale"
    t.index ["severity_id"], name: "index_severity_translations_on_severity_id"
  end

  create_table "species", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "species_class"
    t.string "sub_species"
    t.string "species_family"
    t.string "species_kingdom"
    t.string "scientific_name"
    t.string "cites_status"
    t.integer "cites_id"
    t.integer "iucn_status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "species_countries", id: :serial, force: :cascade do |t|
    t.integer "country_id"
    t.integer "species_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["country_id"], name: "index_species_countries_on_country_id"
    t.index ["species_id"], name: "index_species_countries_on_species_id"
  end

  create_table "species_observations", id: :serial, force: :cascade do |t|
    t.integer "observation_id"
    t.integer "species_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_species_observations_on_deleted_at"
    t.index ["observation_id"], name: "index_species_observations_on_observation_id"
    t.index ["species_id"], name: "index_species_observations_on_species_id"
  end

  create_table "species_translations", id: :serial, force: :cascade do |t|
    t.integer "species_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "common_name"
    t.index ["locale"], name: "index_species_translations_on_locale"
    t.index ["species_id"], name: "index_species_translations_on_species_id"
  end

  create_table "subcategories", id: :serial, force: :cascade do |t|
    t.integer "category_id"
    t.integer "subcategory_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "location_required", default: true, null: false
    t.index ["category_id"], name: "index_subcategories_on_category_id"
    t.index ["subcategory_type"], name: "index_subcategories_on_subcategory_type"
  end

  create_table "subcategory_translations", id: :serial, force: :cascade do |t|
    t.integer "subcategory_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "name"
    t.text "details"
    t.index ["locale"], name: "index_subcategory_translations_on_locale"
    t.index ["name", "subcategory_id"], name: "index_subcategory_translations_on_name_and_subcategory_id"
    t.index ["subcategory_id"], name: "index_subcategory_translations_on_subcategory_id"
  end

  create_table "tool_translations", id: :serial, force: :cascade do |t|
    t.integer "tool_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.text "description"
    t.index ["locale"], name: "index_tool_translations_on_locale"
    t.index ["tool_id"], name: "index_tool_translations_on_tool_id"
  end

  create_table "tools", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "tutorial_translations", id: :serial, force: :cascade do |t|
    t.integer "tutorial_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.text "description"
    t.index ["locale"], name: "index_tutorial_translations_on_locale"
    t.index ["tutorial_id"], name: "index_tutorial_translations_on_tutorial_id"
  end

  create_table "tutorials", id: :serial, force: :cascade do |t|
    t.integer "position"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "uploaded_documents", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "author"
    t.string "caption"
    t.string "file"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "user_permissions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "user_role", default: 0, null: false
    t.jsonb "permissions", default: {}
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name"
    t.boolean "is_active", default: true, null: false
    t.datetime "deactivated_at", precision: nil
    t.integer "permissions_request"
    t.datetime "permissions_accepted", precision: nil
    t.integer "country_id"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at", precision: nil
    t.integer "observer_id"
    t.integer "operator_id"
    t.integer "holding_id"
    t.string "locale"
    t.string "first_name"
    t.string "last_name"
    t.boolean "organization_account", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["name"], name: "index_users_on_name"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.string "locale"
    t.datetime "created_at", precision: nil
    t.text "object_changes"
    t.index ["item_type", "item_id", "locale"], name: "index_versions_on_item_type_and_item_id_and_locale"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "annex_documents", "operator_document_annexes", on_delete: :cascade
  add_foreign_key "api_keys", "users"
  add_foreign_key "country_links", "countries", on_delete: :cascade
  add_foreign_key "country_responsible_admins", "countries", on_delete: :cascade
  add_foreign_key "country_responsible_admins", "users", on_delete: :cascade
  add_foreign_key "country_vpas", "countries", on_delete: :cascade
  add_foreign_key "gov_documents", "countries", on_delete: :cascade
  add_foreign_key "gov_documents", "required_gov_documents", on_delete: :cascade
  add_foreign_key "gov_documents", "users", on_delete: :cascade
  add_foreign_key "laws", "countries"
  add_foreign_key "laws", "subcategories"
  add_foreign_key "notifications", "notification_groups", on_delete: :nullify
  add_foreign_key "notifications", "operator_documents", on_delete: :cascade
  add_foreign_key "notifications", "users", on_delete: :cascade
  add_foreign_key "observation_documents", "observation_reports"
  add_foreign_key "observation_documents_observations", "observation_documents", on_delete: :cascade
  add_foreign_key "observation_documents_observations", "observations", on_delete: :cascade
  add_foreign_key "observation_histories", "categories", on_delete: :cascade
  add_foreign_key "observation_histories", "countries", on_delete: :cascade
  add_foreign_key "observation_histories", "fmus", on_delete: :cascade
  add_foreign_key "observation_histories", "observations", on_delete: :nullify
  add_foreign_key "observation_histories", "operators", on_delete: :cascade
  add_foreign_key "observation_histories", "subcategories", on_delete: :cascade
  add_foreign_key "observation_operators", "observations"
  add_foreign_key "observation_operators", "operators"
  add_foreign_key "observation_report_observers", "observation_reports"
  add_foreign_key "observation_report_observers", "observers"
  add_foreign_key "observation_report_statistics", "countries", on_delete: :cascade
  add_foreign_key "observation_report_statistics", "observers", on_delete: :cascade
  add_foreign_key "observation_reports", "users"
  add_foreign_key "observation_statistics", "categories", on_delete: :cascade
  add_foreign_key "observation_statistics", "countries", on_delete: :cascade
  add_foreign_key "observation_statistics", "fmus", on_delete: :cascade
  add_foreign_key "observation_statistics", "operators", on_delete: :cascade
  add_foreign_key "observation_statistics", "subcategories", on_delete: :cascade
  add_foreign_key "observations", "countries"
  add_foreign_key "observations", "fmus"
  add_foreign_key "observations", "laws"
  add_foreign_key "observations", "observation_reports"
  add_foreign_key "observations", "operators"
  add_foreign_key "observations", "users"
  add_foreign_key "observations", "users", column: "modified_user_id"
  add_foreign_key "observer_managers", "observers", on_delete: :cascade
  add_foreign_key "observer_managers", "users", on_delete: :cascade
  add_foreign_key "observers", "users", column: "responsible_admin_id", on_delete: :nullify
  add_foreign_key "observers", "users", column: "responsible_qc1_id", on_delete: :nullify
  add_foreign_key "observers", "users", column: "responsible_qc2_id", on_delete: :nullify
  add_foreign_key "operator_document_histories", "operator_documents", on_delete: :nullify
  add_foreign_key "operator_document_histories", "operators", on_delete: :cascade
  add_foreign_key "operator_document_histories", "required_operator_documents", on_delete: :cascade
  add_foreign_key "operator_document_histories", "users", on_delete: :nullify
  add_foreign_key "operator_document_statistics", "countries", on_delete: :cascade
  add_foreign_key "operator_document_statistics", "required_operator_document_groups", on_delete: :cascade
  add_foreign_key "operator_documents", "fmus"
  add_foreign_key "operator_documents", "operators"
  add_foreign_key "operator_documents", "required_operator_documents"
  add_foreign_key "operator_documents", "users", on_delete: :nullify
  add_foreign_key "operators", "holdings", on_delete: :nullify
  add_foreign_key "protected_areas", "countries", on_delete: :cascade
  add_foreign_key "required_gov_document_groups", "required_gov_document_groups", column: "parent_id"
  add_foreign_key "required_gov_documents", "countries", on_delete: :cascade
  add_foreign_key "required_gov_documents", "required_gov_document_groups", on_delete: :cascade
  add_foreign_key "required_operator_documents", "countries"
  add_foreign_key "required_operator_documents", "required_operator_document_groups"
  add_foreign_key "sawmills", "operators"
  add_foreign_key "score_operator_documents", "operators", on_delete: :cascade
  add_foreign_key "score_operator_observations", "operators", on_delete: :cascade
  add_foreign_key "severities", "subcategories"
  add_foreign_key "subcategories", "categories"
  add_foreign_key "user_permissions", "users"
  add_foreign_key "users", "countries"
  add_foreign_key "users", "holdings", on_delete: :nullify
end

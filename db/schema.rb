# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170421123102) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "citext"

  create_table "annex_governance_translations", force: :cascade do |t|
    t.integer  "annex_governance_id", null: false
    t.string   "locale",              null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "governance_pillar"
    t.text     "governance_problem"
    t.text     "details"
    t.index ["annex_governance_id"], name: "index_annex_governance_translations_on_annex_governance_id", using: :btree
    t.index ["locale"], name: "index_annex_governance_translations_on_locale", using: :btree
  end

  create_table "annex_governances", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "annex_operator_laws", force: :cascade do |t|
    t.integer  "annex_operator_id"
    t.integer  "law_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.index ["annex_operator_id"], name: "index_annex_operator_laws_on_annex_operator_id", using: :btree
    t.index ["law_id"], name: "index_annex_operator_laws_on_law_id", using: :btree
  end

  create_table "annex_operator_translations", force: :cascade do |t|
    t.integer  "annex_operator_id", null: false
    t.string   "locale",            null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "illegality"
    t.text     "details"
    t.index ["annex_operator_id"], name: "index_annex_operator_translations_on_annex_operator_id", using: :btree
    t.index ["locale"], name: "index_annex_operator_translations_on_locale", using: :btree
  end

  create_table "annex_operators", force: :cascade do |t|
    t.integer  "country_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_annex_operators_on_country_id", using: :btree
  end

  create_table "api_keys", force: :cascade do |t|
    t.string   "access_token"
    t.datetime "expires_at"
    t.integer  "user_id"
    t.boolean  "is_active",    default: true
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["access_token"], name: "index_api_keys_on_access_token", unique: true, using: :btree
    t.index ["user_id"], name: "index_api_keys_on_user_id", using: :btree
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categorings", force: :cascade do |t|
    t.integer  "category_id",        null: false
    t.integer  "categorizable_id"
    t.string   "categorizable_type"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["categorizable_id", "categorizable_type"], name: "categorizable_index", using: :btree
    t.index ["category_id", "categorizable_id", "categorizable_type"], name: "category_categorizable_index", unique: true, using: :btree
    t.index ["category_id"], name: "index_categorings_on_category_id", using: :btree
  end

  create_table "category_translations", force: :cascade do |t|
    t.integer  "category_id", null: false
    t.string   "locale",      null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "name"
    t.index ["category_id"], name: "index_category_translations_on_category_id", using: :btree
    t.index ["locale"], name: "index_category_translations_on_locale", using: :btree
  end

  create_table "comments", force: :cascade do |t|
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.text     "body"
    t.integer  "user_id",          null: false
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["commentable_id", "commentable_type"], name: "index_comments_on_commentable_id_and_commentable_type", using: :btree
    t.index ["user_id"], name: "index_comments_on_user_id", using: :btree
  end

  create_table "countries", force: :cascade do |t|
    t.string   "iso"
    t.string   "region_iso"
    t.jsonb    "country_centroid"
    t.jsonb    "region_centroid"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.boolean  "is_active",        default: false, null: false
  end

  create_table "country_translations", force: :cascade do |t|
    t.integer  "country_id",  null: false
    t.string   "locale",      null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "name"
    t.string   "region_name"
    t.index ["country_id"], name: "index_country_translations_on_country_id", using: :btree
    t.index ["locale"], name: "index_country_translations_on_locale", using: :btree
  end

  create_table "documents", force: :cascade do |t|
    t.string   "name"
    t.string   "document_type"
    t.string   "attachment"
    t.integer  "attacheable_id"
    t.string   "attacheable_type"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "user_id"
    t.index ["attacheable_id", "attacheable_type"], name: "documents_attacheable_index", using: :btree
  end

  create_table "government_translations", force: :cascade do |t|
    t.integer  "government_id",     null: false
    t.string   "locale",            null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "government_entity"
    t.text     "details"
    t.index ["government_id"], name: "index_government_translations_on_government_id", using: :btree
    t.index ["locale"], name: "index_government_translations_on_locale", using: :btree
  end

  create_table "governments", force: :cascade do |t|
    t.integer  "country_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_governments_on_country_id", using: :btree
  end

  create_table "law_translations", force: :cascade do |t|
    t.integer  "law_id",          null: false
    t.string   "locale",          null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "legal_reference"
    t.string   "legal_penalty"
    t.index ["law_id"], name: "index_law_translations_on_law_id", using: :btree
    t.index ["locale"], name: "index_law_translations_on_locale", using: :btree
  end

  create_table "laws", force: :cascade do |t|
    t.integer  "country_id"
    t.string   "vpa_indicator"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["country_id"], name: "index_laws_on_country_id", using: :btree
  end

  create_table "observation_translations", force: :cascade do |t|
    t.integer  "observation_id",    null: false
    t.string   "locale",            null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.text     "details"
    t.string   "evidence"
    t.text     "concern_opinion"
    t.string   "litigation_status"
    t.index ["locale"], name: "index_observation_translations_on_locale", using: :btree
    t.index ["observation_id"], name: "index_observation_translations_on_observation_id", using: :btree
  end

  create_table "observations", force: :cascade do |t|
    t.integer  "annex_operator_id"
    t.integer  "annex_governance_id"
    t.integer  "severity_id"
    t.string   "observation_type",                   null: false
    t.integer  "user_id"
    t.datetime "publication_date"
    t.integer  "country_id"
    t.integer  "observer_id"
    t.integer  "operator_id"
    t.integer  "government_id"
    t.string   "pv"
    t.boolean  "is_active",           default: true
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.index ["annex_governance_id"], name: "index_observations_on_annex_governance_id", using: :btree
    t.index ["annex_operator_id"], name: "index_observations_on_annex_operator_id", using: :btree
    t.index ["country_id"], name: "index_observations_on_country_id", using: :btree
    t.index ["government_id"], name: "index_observations_on_government_id", using: :btree
    t.index ["observer_id"], name: "index_observations_on_observer_id", using: :btree
    t.index ["operator_id"], name: "index_observations_on_operator_id", using: :btree
    t.index ["severity_id"], name: "index_observations_on_severity_id", using: :btree
  end

  create_table "observer_translations", force: :cascade do |t|
    t.integer  "observer_id",  null: false
    t.string   "locale",       null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "name"
    t.string   "organization"
    t.index ["locale"], name: "index_observer_translations_on_locale", using: :btree
    t.index ["observer_id"], name: "index_observer_translations_on_observer_id", using: :btree
  end

  create_table "observers", force: :cascade do |t|
    t.string   "observer_type",                null: false
    t.integer  "country_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.boolean  "is_active",     default: true
    t.string   "logo"
    t.index ["country_id"], name: "index_observers_on_country_id", using: :btree
  end

  create_table "operator_translations", force: :cascade do |t|
    t.integer  "operator_id", null: false
    t.string   "locale",      null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "name"
    t.text     "details"
    t.index ["locale"], name: "index_operator_translations_on_locale", using: :btree
    t.index ["operator_id"], name: "index_operator_translations_on_operator_id", using: :btree
  end

  create_table "operators", force: :cascade do |t|
    t.string   "operator_type"
    t.integer  "country_id"
    t.string   "concession"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.boolean  "is_active",     default: true
    t.string   "logo"
    t.index ["country_id"], name: "index_operators_on_country_id", using: :btree
  end

  create_table "photos", force: :cascade do |t|
    t.string   "name"
    t.string   "attachment"
    t.integer  "attacheable_id"
    t.string   "attacheable_type"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.integer  "user_id"
    t.index ["attacheable_id", "attacheable_type"], name: "photos_attacheable_index", using: :btree
  end

  create_table "severities", force: :cascade do |t|
    t.integer  "level"
    t.integer  "severable_id",   null: false
    t.string   "severable_type", null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["level", "severable_id", "severable_type"], name: "index_severities_on_level_and_severable_id_and_severable_type", unique: true, using: :btree
    t.index ["severable_id", "severable_type"], name: "index_severities_on_severable_id_and_severable_type", using: :btree
  end

  create_table "severity_translations", force: :cascade do |t|
    t.integer  "severity_id", null: false
    t.string   "locale",      null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.text     "details"
    t.index ["locale"], name: "index_severity_translations_on_locale", using: :btree
    t.index ["severity_id"], name: "index_severity_translations_on_severity_id", using: :btree
  end

  create_table "species", force: :cascade do |t|
    t.string   "name"
    t.string   "species_class"
    t.string   "sub_species"
    t.string   "species_family"
    t.string   "species_kingdom"
    t.string   "scientific_name"
    t.string   "cites_status"
    t.integer  "cites_id"
    t.integer  "iucn_status"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "species_countries", force: :cascade do |t|
    t.integer  "country_id"
    t.integer  "species_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_species_countries_on_country_id", using: :btree
    t.index ["species_id"], name: "index_species_countries_on_species_id", using: :btree
  end

  create_table "species_observations", force: :cascade do |t|
    t.integer  "observation_id"
    t.integer  "species_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["observation_id"], name: "index_species_observations_on_observation_id", using: :btree
    t.index ["species_id"], name: "index_species_observations_on_species_id", using: :btree
  end

  create_table "species_translations", force: :cascade do |t|
    t.integer  "species_id",  null: false
    t.string   "locale",      null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "common_name"
    t.index ["locale"], name: "index_species_translations_on_locale", using: :btree
    t.index ["species_id"], name: "index_species_translations_on_species_id", using: :btree
  end

  create_table "user_observers", force: :cascade do |t|
    t.integer  "observer_id"
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["observer_id"], name: "index_user_observers_on_observer_id", using: :btree
    t.index ["user_id"], name: "index_user_observers_on_user_id", using: :btree
  end

  create_table "user_operators", force: :cascade do |t|
    t.integer  "operator_id"
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["operator_id"], name: "index_user_operators_on_operator_id", using: :btree
    t.index ["user_id"], name: "index_user_operators_on_user_id", using: :btree
  end

  create_table "user_permissions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "user_role",   default: 0,  null: false
    t.jsonb    "permissions", default: {}
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.string   "password_digest"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "nickname"
    t.string   "name"
    t.string   "institution"
    t.string   "web_url"
    t.boolean  "is_active",            default: true
    t.datetime "deactivated_at"
    t.integer  "permissions_request"
    t.datetime "permissions_accepted"
    t.integer  "country_id"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
  end

  add_foreign_key "annex_operators", "countries"
  add_foreign_key "api_keys", "users"
  add_foreign_key "categorings", "categories"
  add_foreign_key "comments", "users"
  add_foreign_key "documents", "users"
  add_foreign_key "laws", "countries"
  add_foreign_key "observations", "countries"
  add_foreign_key "observations", "governments"
  add_foreign_key "observations", "observers"
  add_foreign_key "observations", "operators"
  add_foreign_key "observers", "countries"
  add_foreign_key "photos", "users"
  add_foreign_key "user_permissions", "users"
  add_foreign_key "users", "countries"
end

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

ActiveRecord::Schema.define(version: 20220523191728) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "address_standardizer"
  enable_extension "address_standardizer_data_us"
  enable_extension "citext"
  enable_extension "fuzzystrmatch"
  enable_extension "postgis_tiger_geocoder"
  enable_extension "postgis_topology"

  create_table "about_page_entries", force: :cascade do |t|
    t.integer  "position",   null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_about_page_entries_on_position", using: :btree
  end

  create_table "about_page_entry_translations", force: :cascade do |t|
    t.integer  "about_page_entry_id", null: false
    t.string   "locale",              null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "title"
    t.text     "body"
    t.index ["about_page_entry_id"], name: "index_about_page_entry_translations_on_about_page_entry_id", using: :btree
    t.index ["locale"], name: "index_about_page_entry_translations_on_locale", using: :btree
  end

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_type"
    t.integer  "resource_id"
    t.string   "author_type"
    t.integer  "author_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree
  end

  create_table "annex_documents", force: :cascade do |t|
    t.string   "documentable_type",          null: false
    t.integer  "documentable_id",            null: false
    t.integer  "operator_document_annex_id", null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["documentable_id"], name: "index_annex_documents_on_documentable_id", using: :btree
    t.index ["documentable_type"], name: "index_annex_documents_on_documentable_type", using: :btree
    t.index ["operator_document_annex_id"], name: "index_annex_documents_on_operator_document_annex_id", using: :btree
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
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "category_type"
  end

  create_table "category_translations", force: :cascade do |t|
    t.integer  "category_id", null: false
    t.string   "locale",      null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "name"
    t.index ["category_id"], name: "index_category_translations_on_category_id", using: :btree
    t.index ["locale"], name: "index_category_translations_on_locale", using: :btree
    t.index ["name", "category_id"], name: "index_category_translations_on_name_and_category_id", using: :btree
  end


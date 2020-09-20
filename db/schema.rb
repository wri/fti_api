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

ActiveRecord::Schema.define(version: 20200918154735) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "address_standardizer"
  enable_extension "address_standardizer_data_us"
  enable_extension "citext"
  enable_extension "fuzzystrmatch"
  enable_extension "postgis"
  enable_extension "postgis_tiger_geocoder"
  enable_extension "postgis_topology"

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

  create_table "addr", primary_key: "gid", force: :cascade do |t|
    t.bigint  "tlid"
    t.string  "fromhn",    limit: 12
    t.string  "tohn",      limit: 12
    t.string  "side",      limit: 1
    t.string  "zip",       limit: 5
    t.string  "plus4",     limit: 4
    t.string  "fromtyp",   limit: 1
    t.string  "totyp",     limit: 1
    t.integer "fromarmid"
    t.integer "toarmid"
    t.string  "arid",      limit: 22
    t.string  "mtfcc",     limit: 5
    t.string  "statefp",   limit: 2
    t.index ["tlid", "statefp"], name: "idx_tiger_addr_tlid_statefp", using: :btree
    t.index ["zip"], name: "idx_tiger_addr_zip", using: :btree
  end

  create_table "addrfeat", primary_key: "gid", force: :cascade do |t|
    t.bigint   "tlid"
    t.string   "statefp",    limit: 2,                                   null: false
    t.string   "aridl",      limit: 22
    t.string   "aridr",      limit: 22
    t.string   "linearid",   limit: 22
    t.string   "fullname",   limit: 100
    t.string   "lfromhn",    limit: 12
    t.string   "ltohn",      limit: 12
    t.string   "rfromhn",    limit: 12
    t.string   "rtohn",      limit: 12
    t.string   "zipl",       limit: 5
    t.string   "zipr",       limit: 5
    t.string   "edge_mtfcc", limit: 5
    t.string   "parityl",    limit: 1
    t.string   "parityr",    limit: 1
    t.string   "plus4l",     limit: 4
    t.string   "plus4r",     limit: 4
    t.string   "lfromtyp",   limit: 1
    t.string   "ltotyp",     limit: 1
    t.string   "rfromtyp",   limit: 1
    t.string   "rtotyp",     limit: 1
    t.string   "offsetl",    limit: 1
    t.string   "offsetr",    limit: 1
    t.geometry "the_geom",   limit: {:srid=>4269, :type=>"line_string"}
    t.index ["the_geom"], name: "idx_addrfeat_geom_gist", using: :gist
    t.index ["tlid"], name: "idx_addrfeat_tlid", using: :btree
    t.index ["zipl"], name: "idx_addrfeat_zipl", using: :btree
    t.index ["zipr"], name: "idx_addrfeat_zipr", using: :btree
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

  create_table "bg", primary_key: "bg_id", id: :string, limit: 12, force: :cascade, comment: "block groups" do |t|
    t.serial   "gid",                                                    null: false
    t.string   "statefp",  limit: 2
    t.string   "countyfp", limit: 3
    t.string   "tractce",  limit: 6
    t.string   "blkgrpce", limit: 1
    t.string   "namelsad", limit: 13
    t.string   "mtfcc",    limit: 5
    t.string   "funcstat", limit: 1
    t.float    "aland"
    t.float    "awater"
    t.string   "intptlat", limit: 11
    t.string   "intptlon", limit: 12
    t.geometry "the_geom", limit: {:srid=>4269, :type=>"multi_polygon"}
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

  create_table "contacts", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contributor_translations", force: :cascade do |t|
    t.integer  "contributor_id", null: false
    t.string   "locale",         null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "name",           null: false
    t.text     "description"
    t.index ["contributor_id"], name: "index_contributor_translations_on_contributor_id", using: :btree
    t.index ["locale"], name: "index_contributor_translations_on_locale", using: :btree
  end

  create_table "contributors", force: :cascade do |t|
    t.string   "website"
    t.string   "logo"
    t.integer  "priority"
    t.integer  "category"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "type",       default: "Partner"
    t.index ["type"], name: "index_contributors_on_type", using: :btree
  end

  create_table "countries", force: :cascade do |t|
    t.string   "iso"
    t.string   "region_iso"
    t.jsonb    "country_centroid"
    t.jsonb    "region_centroid"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.boolean  "is_active",                  default: false, null: false
    t.float    "percentage_valid_documents"
    t.index ["is_active"], name: "index_countries_on_is_active", using: :btree
    t.index ["iso"], name: "index_countries_on_iso", using: :btree
  end

  create_table "countries_observers", id: false, force: :cascade do |t|
    t.integer "country_id",  null: false
    t.integer "observer_id", null: false
    t.index ["country_id", "observer_id"], name: "index_countries_observers_on_country_id_and_observer_id", using: :btree
    t.index ["country_id", "observer_id"], name: "index_unique_country_observer", unique: true, using: :btree
    t.index ["observer_id", "country_id"], name: "index_countries_observers_on_observer_id_and_country_id", using: :btree
  end

  create_table "country_link_translations", force: :cascade do |t|
    t.integer  "country_link_id", null: false
    t.string   "locale",          null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "name"
    t.text     "description"
    t.index ["country_link_id"], name: "index_country_link_translations_on_country_link_id", using: :btree
    t.index ["locale"], name: "index_country_link_translations_on_locale", using: :btree
  end

  create_table "country_links", force: :cascade do |t|
    t.string   "url"
    t.boolean  "active",     default: true
    t.integer  "position"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "country_id"
    t.index ["country_id"], name: "index_country_links_on_country_id", using: :btree
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

  create_table "country_vpa_translations", force: :cascade do |t|
    t.integer  "country_vpa_id", null: false
    t.string   "locale",         null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "name"
    t.text     "description"
    t.index ["country_vpa_id"], name: "index_country_vpa_translations_on_country_vpa_id", using: :btree
    t.index ["locale"], name: "index_country_vpa_translations_on_locale", using: :btree
  end

  create_table "country_vpas", force: :cascade do |t|
    t.string   "url"
    t.boolean  "active",     default: true
    t.integer  "position"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "country_id"
    t.index ["country_id"], name: "index_country_vpas_on_country_id", using: :btree
  end

  create_table "county", primary_key: "cntyidfp", id: :string, limit: 5, force: :cascade do |t|
    t.serial   "gid",                                                    null: false
    t.string   "statefp",  limit: 2
    t.string   "countyfp", limit: 3
    t.string   "countyns", limit: 8
    t.string   "name",     limit: 100
    t.string   "namelsad", limit: 100
    t.string   "lsad",     limit: 2
    t.string   "classfp",  limit: 2
    t.string   "mtfcc",    limit: 5
    t.string   "csafp",    limit: 3
    t.string   "cbsafp",   limit: 5
    t.string   "metdivfp", limit: 5
    t.string   "funcstat", limit: 1
    t.bigint   "aland"
    t.float    "awater"
    t.string   "intptlat", limit: 11
    t.string   "intptlon", limit: 12
    t.geometry "the_geom", limit: {:srid=>4269, :type=>"multi_polygon"}
    t.index ["countyfp"], name: "idx_tiger_county", using: :btree
    t.index ["gid"], name: "uidx_county_gid", unique: true, using: :btree
  end

  create_table "county_lookup", primary_key: ["st_code", "co_code"], force: :cascade do |t|
    t.integer "st_code",            null: false
    t.string  "state",   limit: 2
    t.integer "co_code",            null: false
    t.string  "name",    limit: 90
    t.index "soundex((name)::text)", name: "county_lookup_name_idx", using: :btree
    t.index ["state"], name: "county_lookup_state_idx", using: :btree
  end

  create_table "countysub_lookup", primary_key: ["st_code", "co_code", "cs_code"], force: :cascade do |t|
    t.integer "st_code",            null: false
    t.string  "state",   limit: 2
    t.integer "co_code",            null: false
    t.string  "county",  limit: 90
    t.integer "cs_code",            null: false
    t.string  "name",    limit: 90
    t.index "soundex((name)::text)", name: "countysub_lookup_name_idx", using: :btree
    t.index ["state"], name: "countysub_lookup_state_idx", using: :btree
  end

  create_table "cousub", primary_key: "cosbidfp", id: :string, limit: 10, force: :cascade do |t|
    t.serial   "gid",                                                                   null: false
    t.string   "statefp",  limit: 2
    t.string   "countyfp", limit: 3
    t.string   "cousubfp", limit: 5
    t.string   "cousubns", limit: 8
    t.string   "name",     limit: 100
    t.string   "namelsad", limit: 100
    t.string   "lsad",     limit: 2
    t.string   "classfp",  limit: 2
    t.string   "mtfcc",    limit: 5
    t.string   "cnectafp", limit: 3
    t.string   "nectafp",  limit: 5
    t.string   "nctadvfp", limit: 5
    t.string   "funcstat", limit: 1
    t.decimal  "aland",                                                  precision: 14
    t.decimal  "awater",                                                 precision: 14
    t.string   "intptlat", limit: 11
    t.string   "intptlon", limit: 12
    t.geometry "the_geom", limit: {:srid=>4269, :type=>"multi_polygon"}
    t.index ["gid"], name: "uidx_cousub_gid", unique: true, using: :btree
    t.index ["the_geom"], name: "tige_cousub_the_geom_gist", using: :gist
  end

  create_table "direction_lookup", primary_key: "name", id: :string, limit: 20, force: :cascade do |t|
    t.string "abbrev", limit: 3
    t.index ["abbrev"], name: "direction_lookup_abbrev_idx", using: :btree
  end

  create_table "edges", primary_key: "gid", force: :cascade do |t|
    t.string   "statefp",    limit: 2
    t.string   "countyfp",   limit: 3
    t.bigint   "tlid"
    t.decimal  "tfidl",                                                        precision: 10
    t.decimal  "tfidr",                                                        precision: 10
    t.string   "mtfcc",      limit: 5
    t.string   "fullname",   limit: 100
    t.string   "smid",       limit: 22
    t.string   "lfromadd",   limit: 12
    t.string   "ltoadd",     limit: 12
    t.string   "rfromadd",   limit: 12
    t.string   "rtoadd",     limit: 12
    t.string   "zipl",       limit: 5
    t.string   "zipr",       limit: 5
    t.string   "featcat",    limit: 1
    t.string   "hydroflg",   limit: 1
    t.string   "railflg",    limit: 1
    t.string   "roadflg",    limit: 1
    t.string   "olfflg",     limit: 1
    t.string   "passflg",    limit: 1
    t.string   "divroad",    limit: 1
    t.string   "exttyp",     limit: 1
    t.string   "ttyp",       limit: 1
    t.string   "deckedroad", limit: 1
    t.string   "artpath",    limit: 1
    t.string   "persist",    limit: 1
    t.string   "gcseflg",    limit: 1
    t.string   "offsetl",    limit: 1
    t.string   "offsetr",    limit: 1
    t.decimal  "tnidf",                                                        precision: 10
    t.decimal  "tnidt",                                                        precision: 10
    t.geometry "the_geom",   limit: {:srid=>4269, :type=>"multi_line_string"}
    t.index ["countyfp"], name: "idx_tiger_edges_countyfp", using: :btree
    t.index ["the_geom"], name: "idx_tiger_edges_the_geom_gist", using: :gist
    t.index ["tlid"], name: "idx_edges_tlid", using: :btree
  end

  create_table "faces", primary_key: "gid", force: :cascade do |t|
    t.decimal  "tfid",                                                     precision: 10
    t.string   "statefp00",  limit: 2
    t.string   "countyfp00", limit: 3
    t.string   "tractce00",  limit: 6
    t.string   "blkgrpce00", limit: 1
    t.string   "blockce00",  limit: 4
    t.string   "cousubfp00", limit: 5
    t.string   "submcdfp00", limit: 5
    t.string   "conctyfp00", limit: 5
    t.string   "placefp00",  limit: 5
    t.string   "aiannhfp00", limit: 5
    t.string   "aiannhce00", limit: 4
    t.string   "comptyp00",  limit: 1
    t.string   "trsubfp00",  limit: 5
    t.string   "trsubce00",  limit: 3
    t.string   "anrcfp00",   limit: 5
    t.string   "elsdlea00",  limit: 5
    t.string   "scsdlea00",  limit: 5
    t.string   "unsdlea00",  limit: 5
    t.string   "uace00",     limit: 5
    t.string   "cd108fp",    limit: 2
    t.string   "sldust00",   limit: 3
    t.string   "sldlst00",   limit: 3
    t.string   "vtdst00",    limit: 6
    t.string   "zcta5ce00",  limit: 5
    t.string   "tazce00",    limit: 6
    t.string   "ugace00",    limit: 5
    t.string   "puma5ce00",  limit: 5
    t.string   "statefp",    limit: 2
    t.string   "countyfp",   limit: 3
    t.string   "tractce",    limit: 6
    t.string   "blkgrpce",   limit: 1
    t.string   "blockce",    limit: 4
    t.string   "cousubfp",   limit: 5
    t.string   "submcdfp",   limit: 5
    t.string   "conctyfp",   limit: 5
    t.string   "placefp",    limit: 5
    t.string   "aiannhfp",   limit: 5
    t.string   "aiannhce",   limit: 4
    t.string   "comptyp",    limit: 1
    t.string   "trsubfp",    limit: 5
    t.string   "trsubce",    limit: 3
    t.string   "anrcfp",     limit: 5
    t.string   "ttractce",   limit: 6
    t.string   "tblkgpce",   limit: 1
    t.string   "elsdlea",    limit: 5
    t.string   "scsdlea",    limit: 5
    t.string   "unsdlea",    limit: 5
    t.string   "uace",       limit: 5
    t.string   "cd111fp",    limit: 2
    t.string   "sldust",     limit: 3
    t.string   "sldlst",     limit: 3
    t.string   "vtdst",      limit: 6
    t.string   "zcta5ce",    limit: 5
    t.string   "tazce",      limit: 6
    t.string   "ugace",      limit: 5
    t.string   "puma5ce",    limit: 5
    t.string   "csafp",      limit: 3
    t.string   "cbsafp",     limit: 5
    t.string   "metdivfp",   limit: 5
    t.string   "cnectafp",   limit: 3
    t.string   "nectafp",    limit: 5
    t.string   "nctadvfp",   limit: 5
    t.string   "lwflag",     limit: 1
    t.string   "offset",     limit: 1
    t.float    "atotal"
    t.string   "intptlat",   limit: 11
    t.string   "intptlon",   limit: 12
    t.geometry "the_geom",   limit: {:srid=>4269, :type=>"multi_polygon"}
    t.index ["countyfp"], name: "idx_tiger_faces_countyfp", using: :btree
    t.index ["tfid"], name: "idx_tiger_faces_tfid", using: :btree
    t.index ["the_geom"], name: "tiger_faces_the_geom_gist", using: :gist
  end

  create_table "faq_translations", force: :cascade do |t|
    t.integer  "faq_id",     null: false
    t.string   "locale",     null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "question"
    t.text     "answer"
    t.index ["faq_id"], name: "index_faq_translations_on_faq_id", using: :btree
    t.index ["locale"], name: "index_faq_translations_on_locale", using: :btree
  end

  create_table "faqs", force: :cascade do |t|
    t.integer  "position",   null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "image"
  end

  create_table "featnames", primary_key: "gid", force: :cascade do |t|
    t.bigint "tlid"
    t.string "fullname",   limit: 100
    t.string "name",       limit: 100
    t.string "predirabrv", limit: 15
    t.string "pretypabrv", limit: 50
    t.string "prequalabr", limit: 15
    t.string "sufdirabrv", limit: 15
    t.string "suftypabrv", limit: 50
    t.string "sufqualabr", limit: 15
    t.string "predir",     limit: 2
    t.string "pretyp",     limit: 3
    t.string "prequal",    limit: 2
    t.string "sufdir",     limit: 2
    t.string "suftyp",     limit: 3
    t.string "sufqual",    limit: 2
    t.string "linearid",   limit: 22
    t.string "mtfcc",      limit: 5
    t.string "paflag",     limit: 1
    t.string "statefp",    limit: 2
    t.index "lower((name)::text)", name: "idx_tiger_featnames_lname", using: :btree
    t.index "soundex((name)::text)", name: "idx_tiger_featnames_snd_name", using: :btree
    t.index ["tlid", "statefp"], name: "idx_tiger_featnames_tlid_statefp", using: :btree
  end

  create_table "fmu_operators", force: :cascade do |t|
    t.integer  "fmu_id",      null: false
    t.integer  "operator_id", null: false
    t.boolean  "current",     null: false
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["fmu_id", "operator_id"], name: "index_fmu_operators_on_fmu_id_and_operator_id", using: :btree
    t.index ["operator_id", "fmu_id"], name: "index_fmu_operators_on_operator_id_and_fmu_id", using: :btree
  end

  create_table "fmu_translations", force: :cascade do |t|
    t.integer  "fmu_id",     null: false
    t.string   "locale",     null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "name"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_fmu_translations_on_deleted_at", using: :btree
    t.index ["fmu_id"], name: "index_fmu_translations_on_fmu_id", using: :btree
    t.index ["locale"], name: "index_fmu_translations_on_locale", using: :btree
  end

  create_table "fmus", force: :cascade do |t|
    t.integer  "country_id"
    t.jsonb    "geojson"
    t.datetime "created_at",                                                                 null: false
    t.datetime "updated_at",                                                                 null: false
    t.boolean  "certification_fsc",                                          default: false
    t.boolean  "certification_pefc",                                         default: false
    t.boolean  "certification_olb",                                          default: false
    t.boolean  "certification_pafc",                                         default: false
    t.boolean  "certification_fsc_cw",                                       default: false
    t.boolean  "certification_tlv",                                          default: false
    t.integer  "forest_type",                                                default: 0,     null: false
    t.geometry "geometry",             limit: {:srid=>0, :type=>"geometry"}
    t.jsonb    "properties"
    t.datetime "deleted_at"
    t.boolean  "certification_ls",                                           default: false
    t.index ["country_id"], name: "index_fmus_on_country_id", using: :btree
    t.index ["deleted_at"], name: "index_fmus_on_deleted_at", using: :btree
    t.index ["forest_type"], name: "index_fmus_on_forest_type", using: :btree
  end

  create_table "geocode_settings", primary_key: "name", id: :text, force: :cascade do |t|
    t.text "setting"
    t.text "unit"
    t.text "category"
    t.text "short_desc"
  end

  create_table "geocode_settings_default", primary_key: "name", id: :text, force: :cascade do |t|
    t.text "setting"
    t.text "unit"
    t.text "category"
    t.text "short_desc"
  end

  create_table "gov_documents", force: :cascade do |t|
    t.integer  "status",                   null: false
    t.text     "reason"
    t.date     "start_date"
    t.date     "expire_date"
    t.boolean  "current",                  null: false
    t.integer  "uploaded_by"
    t.string   "link"
    t.string   "value"
    t.string   "units"
    t.datetime "deleted_at"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "required_gov_document_id"
    t.integer  "country_id"
    t.integer  "user_id"
    t.index ["country_id"], name: "index_gov_documents_on_country_id", using: :btree
    t.index ["required_gov_document_id"], name: "index_gov_documents_on_required_gov_document_id", using: :btree
    t.index ["user_id"], name: "index_gov_documents_on_user_id", using: :btree
  end

  create_table "gov_files", force: :cascade do |t|
    t.string   "attachment"
    t.datetime "deleted_at"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "gov_document_id"
    t.index ["gov_document_id"], name: "index_gov_files_on_gov_document_id", using: :btree
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
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.boolean  "is_active",  default: true
    t.index ["country_id"], name: "index_governments_on_country_id", using: :btree
  end

  create_table "governments_observations", force: :cascade do |t|
    t.integer  "government_id"
    t.integer  "observation_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["government_id", "observation_id"], name: "governments_observations_association_index", unique: true, using: :btree
    t.index ["government_id"], name: "index_governments_observations_on_government_id", using: :btree
    t.index ["observation_id", "government_id"], name: "observations_governments_association_index", unique: true, using: :btree
    t.index ["observation_id"], name: "index_governments_observations_on_observation_id", using: :btree
  end

  create_table "how_to_translations", force: :cascade do |t|
    t.integer  "how_to_id",   null: false
    t.string   "locale",      null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "name"
    t.text     "description"
    t.index ["how_to_id"], name: "index_how_to_translations_on_how_to_id", using: :btree
    t.index ["locale"], name: "index_how_to_translations_on_locale", using: :btree
  end

  create_table "how_tos", force: :cascade do |t|
    t.integer  "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "laws", force: :cascade do |t|
    t.text     "written_infraction"
    t.text     "infraction"
    t.text     "sanctions"
    t.integer  "min_fine"
    t.integer  "max_fine"
    t.string   "penal_servitude"
    t.text     "other_penalties"
    t.text     "apv"
    t.integer  "subcategory_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.integer  "country_id"
    t.string   "currency"
    t.index ["country_id"], name: "index_laws_on_country_id", using: :btree
    t.index ["subcategory_id"], name: "index_laws_on_subcategory_id", using: :btree
  end

  create_table "loader_lookuptables", primary_key: "lookup_name", id: :text, comment: "This is the table name to inherit from and suffix of resulting output table -- how the table will be named --  edges here would mean -- ma_edges , pa_edges etc. except in the case of national tables. national level tables have no prefix", force: :cascade do |t|
    t.integer "process_order",                   default: 1000,  null: false
    t.text    "table_name",                                                   comment: "suffix of the tables to load e.g.  edges would load all tables like *edges.dbf(shp)  -- so tl_2010_42129_edges.dbf .  "
    t.boolean "single_mode",                     default: true,  null: false
    t.boolean "load",                            default: true,  null: false, comment: "Whether or not to load the table.  For states and zcta5 (you may just want to download states10, zcta510 nationwide file manually) load your own into a single table that inherits from tiger.states, tiger.zcta5.  You'll get improved performance for some geocoding cases."
    t.boolean "level_county",                    default: false, null: false
    t.boolean "level_state",                     default: false, null: false
    t.boolean "level_nation",                    default: false, null: false, comment: "These are tables that contain all data for the whole US so there is just a single file"
    t.text    "post_load_process"
    t.boolean "single_geom_mode",                default: false
    t.string  "insert_mode",           limit: 1, default: "c",   null: false
    t.text    "pre_load_process"
    t.text    "columns_exclude",                                              comment: "List of columns to exclude as an array. This is excluded from both input table and output table and rest of columns remaining are assumed to be in same order in both tables. gid, geoid,cpi,suffix1ce are excluded if no columns are specified.",                              array: true
    t.text    "website_root_override",                                        comment: "Path to use for wget instead of that specified in year table.  Needed currently for zcta where they release that only for 2000 and 2010"
  end

  create_table "loader_platform", primary_key: "os", id: :string, limit: 50, force: :cascade do |t|
    t.text "declare_sect"
    t.text "pgbin"
    t.text "wget"
    t.text "unzip_command"
    t.text "psql"
    t.text "path_sep"
    t.text "loader"
    t.text "environ_set_command"
    t.text "county_process_command"
  end

  create_table "loader_variables", primary_key: "tiger_year", id: :string, limit: 4, force: :cascade do |t|
    t.text "website_root"
    t.text "staging_fold"
    t.text "data_schema"
    t.text "staging_schema"
  end

  create_table "observation_documents", force: :cascade do |t|
    t.string   "name"
    t.string   "attachment"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "user_id"
    t.datetime "deleted_at"
    t.integer  "observation_id"
    t.index ["deleted_at"], name: "index_observation_documents_on_deleted_at", using: :btree
    t.index ["name"], name: "index_observation_documents_on_name", using: :btree
    t.index ["observation_id"], name: "index_observation_documents_on_observation_id", using: :btree
    t.index ["user_id"], name: "index_observation_documents_on_user_id", using: :btree
  end

  create_table "observation_operators", force: :cascade do |t|
    t.integer  "observation_id"
    t.integer  "operator_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["observation_id"], name: "index_observation_operators_on_observation_id", using: :btree
    t.index ["operator_id"], name: "index_observation_operators_on_operator_id", using: :btree
  end

  create_table "observation_report_observers", force: :cascade do |t|
    t.integer  "observation_report_id"
    t.integer  "observer_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.index ["observation_report_id", "observer_id"], name: "index_obs_rep_id_and_observer_id", using: :btree
    t.index ["observer_id", "observation_report_id"], name: "index_observer_id_and_obs_rep_id", using: :btree
  end

  create_table "observation_reports", force: :cascade do |t|
    t.string   "title"
    t.datetime "publication_date"
    t.string   "attachment"
    t.integer  "user_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_observation_reports_on_deleted_at", using: :btree
    t.index ["title"], name: "index_observation_reports_on_title", using: :btree
    t.index ["user_id"], name: "index_observation_reports_on_user_id", using: :btree
  end

  create_table "observation_translations", force: :cascade do |t|
    t.integer  "observation_id",    null: false
    t.string   "locale",            null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.text     "details"
    t.text     "concern_opinion"
    t.string   "litigation_status"
    t.index ["locale"], name: "index_observation_translations_on_locale", using: :btree
    t.index ["observation_id"], name: "index_observation_translations_on_observation_id", using: :btree
  end

  create_table "observations", force: :cascade do |t|
    t.integer  "severity_id"
    t.integer  "observation_type",                      null: false
    t.integer  "user_id"
    t.datetime "publication_date"
    t.integer  "country_id"
    t.integer  "operator_id"
    t.string   "pv"
    t.boolean  "is_active",             default: true
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.decimal  "lat"
    t.decimal  "lng"
    t.integer  "fmu_id"
    t.integer  "subcategory_id"
    t.integer  "validation_status",     default: 0,     null: false
    t.integer  "observation_report_id"
    t.text     "actions_taken"
    t.integer  "modified_user_id"
    t.integer  "law_id"
    t.string   "location_information"
    t.boolean  "is_physical_place",     default: true
    t.integer  "evidence_type"
    t.integer  "location_accuracy"
    t.string   "evidence_on_report"
    t.boolean  "hidden",                default: false
    t.text     "admin_comment"
    t.text     "monitor_comment"
    t.integer  "responsible_admin_id"
    t.index ["country_id"], name: "index_observations_on_country_id", using: :btree
    t.index ["fmu_id"], name: "index_observations_on_fmu_id", using: :btree
    t.index ["hidden"], name: "index_observations_on_hidden", using: :btree
    t.index ["is_active"], name: "index_observations_on_is_active", using: :btree
    t.index ["law_id"], name: "index_observations_on_law_id", using: :btree
    t.index ["observation_report_id"], name: "index_observations_on_observation_report_id", using: :btree
    t.index ["observation_type"], name: "index_observations_on_observation_type", using: :btree
    t.index ["operator_id"], name: "index_observations_on_operator_id", using: :btree
    t.index ["severity_id"], name: "index_observations_on_severity_id", using: :btree
    t.index ["user_id"], name: "index_observations_on_user_id", using: :btree
    t.index ["validation_status"], name: "index_observations_on_validation_status", using: :btree
  end

  create_table "observer_observations", force: :cascade do |t|
    t.integer  "observer_id"
    t.integer  "observation_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["observation_id"], name: "index_observer_observations_on_observation_id", using: :btree
    t.index ["observer_id"], name: "index_observer_observations_on_observer_id", using: :btree
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
    t.string   "observer_type",                    null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.boolean  "is_active",         default: true
    t.string   "logo"
    t.string   "address"
    t.string   "information_name"
    t.string   "information_email"
    t.string   "information_phone"
    t.string   "data_name"
    t.string   "data_email"
    t.string   "data_phone"
    t.string   "organization_type"
    t.index ["is_active"], name: "index_observers_on_is_active", using: :btree
  end

  create_table "operator_document_annexes", force: :cascade do |t|
    t.integer  "operator_document_id"
    t.string   "name"
    t.date     "start_date"
    t.date     "expire_date"
    t.date     "deleted_at"
    t.integer  "status"
    t.string   "attachment"
    t.integer  "uploaded_by"
    t.integer  "user_id"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.boolean  "public",               default: true, null: false
    t.index ["deleted_at"], name: "index_operator_document_annexes_on_deleted_at", using: :btree
    t.index ["operator_document_id"], name: "index_operator_document_annexes_on_operator_document_id", using: :btree
    t.index ["public"], name: "index_operator_document_annexes_on_public", using: :btree
    t.index ["status"], name: "index_operator_document_annexes_on_status", using: :btree
    t.index ["user_id"], name: "index_operator_document_annexes_on_user_id", using: :btree
  end

  create_table "operator_documents", force: :cascade do |t|
    t.string   "type"
    t.date     "expire_date"
    t.date     "start_date"
    t.integer  "fmu_id"
    t.integer  "required_operator_document_id"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.integer  "status"
    t.integer  "operator_id"
    t.string   "attachment"
    t.boolean  "current"
    t.datetime "deleted_at"
    t.integer  "uploaded_by"
    t.integer  "user_id"
    t.text     "reason"
    t.text     "note"
    t.datetime "response_date"
    t.boolean  "public",                        default: true, null: false
    t.integer  "source",                        default: 1
    t.string   "source_info"
    t.index ["current"], name: "index_operator_documents_on_current", using: :btree
    t.index ["deleted_at"], name: "index_operator_documents_on_deleted_at", using: :btree
    t.index ["expire_date"], name: "index_operator_documents_on_expire_date", using: :btree
    t.index ["fmu_id"], name: "index_operator_documents_on_fmu_id", using: :btree
    t.index ["operator_id"], name: "index_operator_documents_on_operator_id", using: :btree
    t.index ["public"], name: "index_operator_documents_on_public", using: :btree
    t.index ["required_operator_document_id"], name: "index_operator_documents_on_required_operator_document_id", using: :btree
    t.index ["source"], name: "index_operator_documents_on_source", using: :btree
    t.index ["start_date"], name: "index_operator_documents_on_start_date", using: :btree
    t.index ["status"], name: "index_operator_documents_on_status", using: :btree
    t.index ["type"], name: "index_operator_documents_on_type", using: :btree
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
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.boolean  "is_active",      default: true
    t.string   "logo"
    t.string   "operator_id"
    t.float    "score_absolute"
    t.float    "obs_per_visit"
    t.string   "fa_id"
    t.string   "address"
    t.string   "website"
    t.boolean  "approved",       default: true, null: false
    t.index ["approved"], name: "index_operators_on_approved", using: :btree
    t.index ["country_id"], name: "index_operators_on_country_id", using: :btree
    t.index ["fa_id"], name: "index_operators_on_fa_id", using: :btree
    t.index ["is_active"], name: "index_operators_on_is_active", using: :btree
  end

  create_table "pagc_gaz", force: :cascade do |t|
    t.integer "seq"
    t.text    "word"
    t.text    "stdword"
    t.integer "token"
    t.boolean "is_custom", default: true, null: false
  end

  create_table "pagc_lex", force: :cascade do |t|
    t.integer "seq"
    t.text    "word"
    t.text    "stdword"
    t.integer "token"
    t.boolean "is_custom", default: true, null: false
  end

  create_table "pagc_rules", force: :cascade do |t|
    t.text    "rule"
    t.boolean "is_custom", default: true
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

  create_table "place", primary_key: "plcidfp", id: :string, limit: 7, force: :cascade do |t|
    t.serial   "gid",                                                    null: false
    t.string   "statefp",  limit: 2
    t.string   "placefp",  limit: 5
    t.string   "placens",  limit: 8
    t.string   "name",     limit: 100
    t.string   "namelsad", limit: 100
    t.string   "lsad",     limit: 2
    t.string   "classfp",  limit: 2
    t.string   "cpi",      limit: 1
    t.string   "pcicbsa",  limit: 1
    t.string   "pcinecta", limit: 1
    t.string   "mtfcc",    limit: 5
    t.string   "funcstat", limit: 1
    t.bigint   "aland"
    t.bigint   "awater"
    t.string   "intptlat", limit: 11
    t.string   "intptlon", limit: 12
    t.geometry "the_geom", limit: {:srid=>4269, :type=>"multi_polygon"}
    t.index ["gid"], name: "uidx_tiger_place_gid", unique: true, using: :btree
    t.index ["the_geom"], name: "tiger_place_the_geom_gist", using: :gist
  end

  create_table "place_lookup", primary_key: ["st_code", "pl_code"], force: :cascade do |t|
    t.integer "st_code",            null: false
    t.string  "state",   limit: 2
    t.integer "pl_code",            null: false
    t.string  "name",    limit: 90
    t.index "soundex((name)::text)", name: "place_lookup_name_idx", using: :btree
    t.index ["state"], name: "place_lookup_state_idx", using: :btree
  end

  create_table "ranking_operator_documents", force: :cascade do |t|
    t.date     "date",                       null: false
    t.boolean  "current",     default: true, null: false
    t.integer  "position",                   null: false
    t.integer  "operator_id"
    t.integer  "country_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["country_id"], name: "index_ranking_operator_documents_on_country_id", using: :btree
    t.index ["current"], name: "index_ranking_operator_documents_on_current", using: :btree
    t.index ["operator_id"], name: "index_ranking_operator_documents_on_operator_id", using: :btree
    t.index ["position", "country_id", "current"], name: "index_rod_on_position_and_country_and_current", using: :btree
  end

  create_table "required_gov_document_group_translations", force: :cascade do |t|
    t.integer  "required_gov_document_group_id", null: false
    t.string   "locale",                         null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "name",                           null: false
    t.text     "description"
    t.index ["locale"], name: "index_required_gov_document_group_translations_on_locale", using: :btree
    t.index ["required_gov_document_group_id"], name: "index_d5783e31f1865cb8918d628281b44e29621b4216", using: :btree
  end

  create_table "required_gov_document_groups", force: :cascade do |t|
    t.integer  "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "required_gov_document_translations", force: :cascade do |t|
    t.integer  "required_gov_document_id", null: false
    t.string   "locale",                   null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.text     "explanation"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_required_gov_document_translations_on_deleted_at", using: :btree
    t.index ["locale"], name: "index_required_gov_document_translations_on_locale", using: :btree
    t.index ["required_gov_document_id"], name: "index_759a54fdd00cf06c291ffc4857fb904934dd47b9", using: :btree
  end

  create_table "required_gov_documents", force: :cascade do |t|
    t.string   "name",                           null: false
    t.integer  "document_type",                  null: false
    t.integer  "valid_period"
    t.datetime "deleted_at"
    t.integer  "required_gov_document_group_id"
    t.integer  "country_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.index ["country_id"], name: "index_required_gov_documents_on_country_id", using: :btree
    t.index ["deleted_at"], name: "index_required_gov_documents_on_deleted_at", using: :btree
    t.index ["document_type"], name: "index_required_gov_documents_on_document_type", using: :btree
    t.index ["required_gov_document_group_id"], name: "index_required_gov_documents_on_required_gov_document_group_id", using: :btree
  end

  create_table "required_operator_document_group_translations", force: :cascade do |t|
    t.integer  "required_operator_document_group_id", null: false
    t.string   "locale",                              null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "name"
    t.index ["locale"], name: "index_required_operator_document_group_translations_on_locale", using: :btree
    t.index ["required_operator_document_group_id"], name: "index_64b55c0cec158f1717cc5d775ae87c7a48f1cc59", using: :btree
  end

  create_table "required_operator_document_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "position"
  end

  create_table "required_operator_document_translations", force: :cascade do |t|
    t.integer  "required_operator_document_id", null: false
    t.string   "locale",                        null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.text     "explanation"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_required_operator_document_translations_on_deleted_at", using: :btree
    t.index ["locale"], name: "index_required_operator_document_translations_on_locale", using: :btree
    t.index ["required_operator_document_id"], name: "index_eed74ed5a0934f32c4b075e5beee98f1ebf34d19", using: :btree
  end

  create_table "required_operator_documents", force: :cascade do |t|
    t.string   "type"
    t.integer  "required_operator_document_group_id"
    t.string   "name"
    t.integer  "country_id"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.integer  "valid_period"
    t.datetime "deleted_at"
    t.integer  "forest_types",                        default: [],                 array: true
    t.boolean  "contract_signature",                  default: false, null: false
    t.index ["contract_signature"], name: "index_required_operator_documents_on_contract_signature", using: :btree
    t.index ["deleted_at"], name: "index_required_operator_documents_on_deleted_at", using: :btree
    t.index ["forest_types"], name: "index_required_operator_documents_on_forest_types", using: :btree
    t.index ["required_operator_document_group_id"], name: "index_req_op_doc_group_id", using: :btree
    t.index ["type"], name: "index_required_operator_documents_on_type", using: :btree
  end

  create_table "sawmills", force: :cascade do |t|
    t.string   "name"
    t.float    "lat"
    t.float    "lng"
    t.boolean  "is_active",   default: true, null: false
    t.integer  "operator_id",                null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.jsonb    "geojson"
  end

  create_table "score_operator_documents", force: :cascade do |t|
    t.date     "date",                       null: false
    t.boolean  "current",     default: true, null: false
    t.float    "all"
    t.float    "country"
    t.float    "fmu"
    t.integer  "operator_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["current"], name: "index_score_operator_documents_on_current", using: :btree
    t.index ["date"], name: "index_score_operator_documents_on_date", using: :btree
    t.index ["operator_id"], name: "index_score_operator_documents_on_operator_id", using: :btree
  end

  create_table "secondary_unit_lookup", primary_key: "name", id: :string, limit: 20, force: :cascade do |t|
    t.string "abbrev", limit: 5
    t.index ["abbrev"], name: "secondary_unit_lookup_abbrev_idx", using: :btree
  end

  create_table "severities", force: :cascade do |t|
    t.integer  "level"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "subcategory_id"
    t.index ["level", "subcategory_id"], name: "index_severities_on_level_and_subcategory_id", using: :btree
    t.index ["subcategory_id", "level"], name: "index_severities_on_subcategory_id_and_level", using: :btree
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

  create_table "state", primary_key: "statefp", id: :string, limit: 2, force: :cascade do |t|
    t.serial   "gid",                                                    null: false
    t.string   "region",   limit: 2
    t.string   "division", limit: 2
    t.string   "statens",  limit: 8
    t.string   "stusps",   limit: 2,                                     null: false
    t.string   "name",     limit: 100
    t.string   "lsad",     limit: 2
    t.string   "mtfcc",    limit: 5
    t.string   "funcstat", limit: 1
    t.bigint   "aland"
    t.bigint   "awater"
    t.string   "intptlat", limit: 11
    t.string   "intptlon", limit: 12
    t.geometry "the_geom", limit: {:srid=>4269, :type=>"multi_polygon"}
    t.index ["gid"], name: "uidx_tiger_state_gid", unique: true, using: :btree
    t.index ["stusps"], name: "uidx_tiger_state_stusps", unique: true, using: :btree
    t.index ["the_geom"], name: "idx_tiger_state_the_geom_gist", using: :gist
  end

  create_table "state_lookup", primary_key: "st_code", id: :integer, force: :cascade do |t|
    t.string "name",    limit: 40
    t.string "abbrev",  limit: 3
    t.string "statefp", limit: 2
    t.index ["abbrev"], name: "state_lookup_abbrev_key", unique: true, using: :btree
    t.index ["name"], name: "state_lookup_name_key", unique: true, using: :btree
    t.index ["statefp"], name: "state_lookup_statefp_key", unique: true, using: :btree
  end

  create_table "street_type_lookup", primary_key: "name", id: :string, limit: 50, force: :cascade do |t|
    t.string  "abbrev", limit: 50
    t.boolean "is_hw",             default: false, null: false
    t.index ["abbrev"], name: "street_type_lookup_abbrev_idx", using: :btree
  end

  create_table "subcategories", force: :cascade do |t|
    t.integer  "category_id"
    t.integer  "subcategory_type"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.boolean  "location_required", default: true
    t.index ["category_id"], name: "index_subcategories_on_category_id", using: :btree
    t.index ["subcategory_type"], name: "index_subcategories_on_subcategory_type", using: :btree
  end

  create_table "subcategory_translations", force: :cascade do |t|
    t.integer  "subcategory_id", null: false
    t.string   "locale",         null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.text     "name"
    t.text     "details"
    t.index ["locale"], name: "index_subcategory_translations_on_locale", using: :btree
    t.index ["subcategory_id"], name: "index_subcategory_translations_on_subcategory_id", using: :btree
  end

  create_table "tabblock", primary_key: "tabblock_id", id: :string, limit: 16, force: :cascade do |t|
    t.serial   "gid",                                                    null: false
    t.string   "statefp",  limit: 2
    t.string   "countyfp", limit: 3
    t.string   "tractce",  limit: 6
    t.string   "blockce",  limit: 4
    t.string   "name",     limit: 20
    t.string   "mtfcc",    limit: 5
    t.string   "ur",       limit: 1
    t.string   "uace",     limit: 5
    t.string   "funcstat", limit: 1
    t.float    "aland"
    t.float    "awater"
    t.string   "intptlat", limit: 11
    t.string   "intptlon", limit: 12
    t.geometry "the_geom", limit: {:srid=>4269, :type=>"multi_polygon"}
  end

  create_table "tool_translations", force: :cascade do |t|
    t.integer  "tool_id",     null: false
    t.string   "locale",      null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "name"
    t.text     "description"
    t.index ["locale"], name: "index_tool_translations_on_locale", using: :btree
    t.index ["tool_id"], name: "index_tool_translations_on_tool_id", using: :btree
  end

  create_table "tools", force: :cascade do |t|
    t.integer  "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tract", primary_key: "tract_id", id: :string, limit: 11, force: :cascade do |t|
    t.serial   "gid",                                                    null: false
    t.string   "statefp",  limit: 2
    t.string   "countyfp", limit: 3
    t.string   "tractce",  limit: 6
    t.string   "name",     limit: 7
    t.string   "namelsad", limit: 20
    t.string   "mtfcc",    limit: 5
    t.string   "funcstat", limit: 1
    t.float    "aland"
    t.float    "awater"
    t.string   "intptlat", limit: 11
    t.string   "intptlon", limit: 12
    t.geometry "the_geom", limit: {:srid=>4269, :type=>"multi_polygon"}
  end

  create_table "tutorial_translations", force: :cascade do |t|
    t.integer  "tutorial_id", null: false
    t.string   "locale",      null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "name"
    t.text     "description"
    t.index ["locale"], name: "index_tutorial_translations_on_locale", using: :btree
    t.index ["tutorial_id"], name: "index_tutorial_translations_on_tutorial_id", using: :btree
  end

  create_table "tutorials", force: :cascade do |t|
    t.integer  "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "uploaded_documents", force: :cascade do |t|
    t.string   "name"
    t.string   "author"
    t.string   "caption"
    t.string   "file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "nickname"
    t.string   "name"
    t.string   "institution"
    t.string   "web_url"
    t.boolean  "is_active",              default: true
    t.datetime "deactivated_at"
    t.integer  "permissions_request"
    t.datetime "permissions_accepted"
    t.integer  "country_id"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer  "sign_in_count",          default: 0,    null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "encrypted_password",     default: "",   null: false
    t.datetime "remember_created_at"
    t.integer  "observer_id"
    t.integer  "operator_id"
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      null: false
    t.bigint   "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.string   "locale"
    t.datetime "created_at"
    t.text     "object_changes"
    t.index ["item_type", "item_id", "locale"], name: "index_versions_on_item_type_and_item_id_and_locale", using: :btree
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  end

  create_table "zcta5", primary_key: ["zcta5ce", "statefp"], force: :cascade do |t|
    t.serial   "gid",                                                    null: false
    t.string   "statefp",  limit: 2,                                     null: false
    t.string   "zcta5ce",  limit: 5,                                     null: false
    t.string   "classfp",  limit: 2
    t.string   "mtfcc",    limit: 5
    t.string   "funcstat", limit: 1
    t.float    "aland"
    t.float    "awater"
    t.string   "intptlat", limit: 11
    t.string   "intptlon", limit: 12
    t.string   "partflg",  limit: 1
    t.geometry "the_geom", limit: {:srid=>4269, :type=>"multi_polygon"}
    t.index ["gid"], name: "uidx_tiger_zcta5_gid", unique: true, using: :btree
  end

  create_table "zip_lookup", primary_key: "zip", id: :integer, force: :cascade do |t|
    t.integer "st_code"
    t.string  "state",   limit: 2
    t.integer "co_code"
    t.string  "county",  limit: 90
    t.integer "cs_code"
    t.string  "cousub",  limit: 90
    t.integer "pl_code"
    t.string  "place",   limit: 90
    t.integer "cnt"
  end

  create_table "zip_lookup_all", id: false, force: :cascade do |t|
    t.integer "zip"
    t.integer "st_code"
    t.string  "state",   limit: 2
    t.integer "co_code"
    t.string  "county",  limit: 90
    t.integer "cs_code"
    t.string  "cousub",  limit: 90
    t.integer "pl_code"
    t.string  "place",   limit: 90
    t.integer "cnt"
  end

  create_table "zip_lookup_base", primary_key: "zip", id: :string, limit: 5, force: :cascade do |t|
    t.string "state",   limit: 40
    t.string "county",  limit: 90
    t.string "city",    limit: 90
    t.string "statefp", limit: 2
  end

  create_table "zip_state", primary_key: ["zip", "stusps"], force: :cascade do |t|
    t.string "zip",     limit: 5, null: false
    t.string "stusps",  limit: 2, null: false
    t.string "statefp", limit: 2
  end

  create_table "zip_state_loc", primary_key: ["zip", "stusps", "place"], force: :cascade do |t|
    t.string "zip",     limit: 5,   null: false
    t.string "stusps",  limit: 2,   null: false
    t.string "statefp", limit: 2
    t.string "place",   limit: 100, null: false
  end

  add_foreign_key "api_keys", "users"
  add_foreign_key "comments", "users"
  add_foreign_key "country_links", "countries", on_delete: :cascade
  add_foreign_key "country_vpas", "countries", on_delete: :cascade
  add_foreign_key "gov_documents", "countries", on_delete: :cascade
  add_foreign_key "gov_documents", "required_gov_documents", on_delete: :cascade
  add_foreign_key "gov_documents", "users", on_delete: :cascade
  add_foreign_key "gov_files", "gov_documents", on_delete: :cascade
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
  add_foreign_key "observations", "laws"
  add_foreign_key "observations", "observation_reports"
  add_foreign_key "observations", "operators"
  add_foreign_key "observations", "users"
  add_foreign_key "operator_documents", "fmus"
  add_foreign_key "operator_documents", "operators"
  add_foreign_key "operator_documents", "required_operator_documents"
  add_foreign_key "photos", "users"
  add_foreign_key "ranking_operator_documents", "countries", on_delete: :cascade
  add_foreign_key "ranking_operator_documents", "operators", on_delete: :cascade
  add_foreign_key "required_gov_documents", "countries", on_delete: :cascade
  add_foreign_key "required_gov_documents", "required_gov_document_groups", on_delete: :cascade
  add_foreign_key "required_operator_documents", "countries"
  add_foreign_key "required_operator_documents", "required_operator_document_groups"
  add_foreign_key "sawmills", "operators"
  add_foreign_key "score_operator_documents", "operators", on_delete: :cascade
  add_foreign_key "severities", "subcategories"
  add_foreign_key "subcategories", "categories"
  add_foreign_key "user_permissions", "users"
  add_foreign_key "users", "countries"
end

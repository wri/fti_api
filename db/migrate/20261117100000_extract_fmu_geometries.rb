class ExtractFmuGeometries < ActiveRecord::Migration[8.0]
  # properties computed at read time (FmuProperties) plus the old cached centroid; everything else is imported data
  DERIVED_PROPERTY_KEYS = %w[id fmu_name iso3_fmu company_na operator_id forest_type fmu_type_label observations centroid certification_fsc certification_pefc certification_olb certification_pafc certification_fsc_cw certification_pbn certification_tlv certification_ls].freeze

  def up
    create_table :fmu_geometries do |t|
      t.references :fmu, type: :integer, null: false, index: {unique: true}, foreign_key: {on_delete: :cascade}
      t.jsonb :geojson
      t.virtual :geometry, type: :geometry, limit: {srid: 0, type: "geometry"}, as: "ST_GeomFromGeoJSON(geojson -> 'geometry')", stored: true
      t.virtual :centroid, type: :geometry, limit: {srid: 0, type: "geometry"}, as: "ST_Centroid(ST_GeomFromGeoJSON(geojson -> 'geometry'))", stored: true
      t.jsonb :source_properties
      t.timestamps
    end
    add_index :fmu_geometries, :geometry, using: :gist

    execute <<~SQL
      INSERT INTO fmu_geometries (fmu_id, geojson, source_properties, created_at, updated_at)
      SELECT id, jsonb_set(geojson, '{properties}', '{}'),
        CASE WHEN jsonb_typeof(geojson -> 'properties') = 'object'
          THEN NULLIF((geojson -> 'properties') - ARRAY[#{DERIVED_PROPERTY_KEYS.map { |k| "'#{k}'" }.join(", ")}], '{}'::jsonb)
        END,
        NOW(), NOW()
      FROM fmus
      WHERE geojson IS NOT NULL
    SQL

    change_table :fmus, bulk: true do |t|
      t.remove :geojson, type: :jsonb
      t.remove :geometry, type: :geometry, limit: {srid: 0, type: "geometry"}
    end
  end

  def down
    change_table :fmus, bulk: true do |t|
      t.jsonb :geojson
      t.geometry :geometry, limit: {srid: 0, type: "geometry"}
      t.index :geometry, using: :gist
    end

    execute <<~SQL
      UPDATE fmus
      SET geojson = jsonb_set(fg.geojson, '{properties}', COALESCE(fg.source_properties, '{}')), geometry = fg.geometry
      FROM fmu_geometries fg
      WHERE fg.fmu_id = fmus.id
    SQL

    drop_table :fmu_geometries
  end
end

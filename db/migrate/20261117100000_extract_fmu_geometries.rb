class ExtractFmuGeometries < ActiveRecord::Migration[8.0]
  def up
    create_table :fmu_geometries do |t|
      t.references :fmu, type: :integer, null: false, index: {unique: true}, foreign_key: {on_delete: :cascade}
      t.jsonb :geojson
      t.geometry :geometry, limit: {srid: 0, type: "geometry"}
      t.timestamps
    end
    add_index :fmu_geometries, :geometry, using: :gist

    execute <<~SQL
      INSERT INTO fmu_geometries (fmu_id, geojson, geometry, created_at, updated_at)
      SELECT id, geojson, geometry, NOW(), NOW()
      FROM fmus
      WHERE geojson IS NOT NULL OR geometry IS NOT NULL
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
      SET geojson = fg.geojson, geometry = fg.geometry
      FROM fmu_geometries fg
      WHERE fg.fmu_id = fmus.id
    SQL

    drop_table :fmu_geometries
  end
end

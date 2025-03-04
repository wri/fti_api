# rubocop:disable all
class CreateProtectedAreas < ActiveRecord::Migration[7.0]
  def change
    create_table :protected_areas do |t|
      t.references :country, foreign_key: {on_delete: :cascade}, index: true, null: false

      t.string :name, null: false
      t.string :wdpa_pid, null: false

      t.jsonb :geojson, null: false
      t.geometry :geometry
      t.virtual :centroid, type: :st_point, as: "ST_Centroid(geometry)", stored: true

      t.timestamps
    end
  end
end

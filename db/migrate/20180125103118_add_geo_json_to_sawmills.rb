class AddGeoJsonToSawmills < ActiveRecord::Migration[5.0]
  def change
    add_column :sawmills, :geojson, :jsonb
  end
end

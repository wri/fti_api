class AddTilePropertiesToFmus < ActiveRecord::Migration[8.0]
  def change
    # Reading geojson->'properties' in the tile query detoasts the whole 16MB geojson
    # column; this copy is ~700 bytes a row, so it stays inline.
    add_column :fmus, :tile_properties, :jsonb, as: "geojson -> 'properties'", stored: true
  end
end

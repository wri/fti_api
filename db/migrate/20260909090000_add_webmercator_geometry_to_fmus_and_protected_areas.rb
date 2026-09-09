class AddWebmercatorGeometryToFmusAndProtectedAreas < ActiveRecord::Migration[8.0]
  def change
    # ST_GeomFromGeoJSON, the only writer of `geometry`, always returns SRID 4326.
    change_table :fmus do |t|
      t.virtual :the_geom_webmercator, type: :geometry,
        as: "ST_Transform(geometry, 3857)", stored: true, srid: 3857, index: {using: :gist}
    end

    change_table :protected_areas do |t|
      t.virtual :the_geom_webmercator, type: :geometry,
        as: "ST_Transform(geometry, 3857)", stored: true, srid: 3857, index: {using: :gist}
    end
  end
end

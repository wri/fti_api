class AddGeometryFieldsToFmus < ActiveRecord::Migration[5.0]
  def change
    add_column :fmus, :geometry, :geometry
    add_column :fmus, :properties, :jsonb

    query =
<<SQL
  WITH g as (
  SELECT *, x.properties as prop, ST_GeomFromGeoJSON(x.geometry) as the_geom
  FROM fmus CROSS JOIN LATERAL
  jsonb_to_record(geojson) AS x("type" TEXT, geometry jsonb, properties jsonb )
  )
  update fmus
  set geometry = g.the_geom , properties = g.prop
  from g
  where fmus.id = g.id;
SQL

    ActiveRecord::Base.connection.execute query
  end
end

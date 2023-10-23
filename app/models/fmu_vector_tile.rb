class FmuVectorTile
  def self.fetch(param_x, param_y, param_z, operator_id)
    begin
      x, y, z = Integer(param_x), Integer(param_y), Integer(param_z)
    rescue ArgumentError, TypeError
      return nil
    end

    operator_condition = operator_id.present? ? sanitize_sql(["AND operator_id=?", operator_id]) : ""

    query = <<~SQL
      SELECT ST_ASMVT(tile.*, 'layer0', 4096, 'mvtgeometry', 'id') as tile
        FROM (
          SELECT id, geojson -> 'properties' as properties, ST_AsMVTGeom(the_geom_webmercator, ST_TileEnvelope(#{z},#{x},#{y}), 4096, 256, true) AS mvtgeometry
          FROM (
            SELECT fmus.*, st_transform(geometry, 3857) as the_geom_webmercator
            FROM fmus
              LEFT JOIN fmu_operators fo on fo.fmu_id = fmus.id and fo.current = true
            WHERE fmus.deleted_at IS NULL #{operator_condition}
          ) as data
          WHERE ST_AsMVTGeom(the_geom_webmercator, ST_TileEnvelope(#{z},#{x},#{y}),4096,0,true) IS NOT NULL
        ) AS tile;
    SQL

    tile = ActiveRecord::Base.connection.execute query
    ActiveRecord::Base.connection.unescape_bytea tile.getvalue(0, 0)
  end
end

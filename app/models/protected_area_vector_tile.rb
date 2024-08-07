class ProtectedAreaVectorTile
  def self.fetch(param_x, param_y, param_z)
    begin
      x, y, z = Integer(param_x), Integer(param_y), Integer(param_z)
    rescue ArgumentError, TypeError
      return nil
    end

    query = <<~SQL
      SELECT ST_ASMVT(tile.*, 'layer0', 4096, 'mvtgeometry', 'id') as tile
        FROM (
          SELECT id, json_build_object('name', name) as properties, ST_AsMVTGeom(the_geom_webmercator, ST_TileEnvelope(#{z},#{x},#{y}), 4096, 256, true) AS mvtgeometry
          FROM (
            SELECT protected_areas.*, st_transform(geometry, 3857) as the_geom_webmercator
            FROM protected_areas
          ) as data
          WHERE ST_AsMVTGeom(the_geom_webmercator, ST_TileEnvelope(#{z},#{x},#{y}),4096,0,true) IS NOT NULL
        ) AS tile;
    SQL

    tile = ActiveRecord::Base.connection.execute query
    ActiveRecord::Base.connection.unescape_bytea tile.getvalue(0, 0)
  end
end

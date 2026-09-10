class FmuVectorTile
  def self.fetch(param_x, param_y, param_z, operator_id)
    begin
      x, y, z = Integer(param_x), Integer(param_y), Integer(param_z)
    rescue ArgumentError, TypeError
      return nil
    end

    operator_condition = if operator_id.present?
      ActiveRecord::Base.sanitize_sql(
        ["AND EXISTS (SELECT 1 FROM fmu_operators fo WHERE fo.fmu_id = fmus.id AND fo.current = true AND fo.operator_id = ?)", operator_id]
      )
    else
      ""
    end

    # && is an index-backed bbox prefilter; it can only exclude rows the
    # ST_AsMVTGeom test below would have excluded anyway, so the tile is unchanged.
    query = <<~SQL
      SELECT ST_AsMVT(tile, 'layer0', 4096, 'mvtgeometry', 'id') as tile
        FROM (
          SELECT fmus.id, fmus.tile_properties as properties,
                 ST_AsMVTGeom(fmus.the_geom_webmercator, ST_TileEnvelope(:z,:x,:y), 4096, 256, true) AS mvtgeometry
          FROM fmus
          WHERE fmus.deleted_at IS NULL
            AND fmus.the_geom_webmercator && ST_TileEnvelope(:z,:x,:y)
            AND ST_AsMVTGeom(fmus.the_geom_webmercator, ST_TileEnvelope(:z,:x,:y), 4096, 0, true) IS NOT NULL
            #{operator_condition}
        ) AS tile;
    SQL

    tile = ActiveRecord::Base.connection.execute ActiveRecord::Base.sanitize_sql([query, {z: z, x: x, y: y}])
    ActiveRecord::Base.connection.unescape_bytea tile.getvalue(0, 0)
  end
end

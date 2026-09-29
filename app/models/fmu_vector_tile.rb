class FmuVectorTile
  def self.fetch(param_x, param_y, param_z, operator_id)
    begin
      x, y, z = Integer(param_x), Integer(param_y), Integer(param_z)
      operator_id = Integer(operator_id) if operator_id.present?
    rescue ArgumentError, TypeError
      return nil
    end
    return nil unless z.between?(0, 30)

    operator_condition = if operator_id.present?
      <<~SQL
        AND EXISTS (
          SELECT 1 FROM fmu_operators fo
          WHERE fo.fmu_id = fmus.id AND fo.current = true AND fo.deleted_at IS NULL AND fo.operator_id = :operator_id
        )
      SQL
    end

    query = <<~SQL
      SELECT ST_AsMVT(tile.*, 'layer0', 4096, 'mvtgeometry', 'id') AS tile
      FROM (
        SELECT fmus.id,
               fmus.geojson -> 'properties' AS properties,
               ST_AsMVTGeom(ST_Transform(ST_Simplify(fmus.geometry, :tolerance, true), 3857), ST_TileEnvelope(:z, :x, :y), 4096, 256, true) AS mvtgeometry
        FROM fmus
        WHERE fmus.deleted_at IS NULL
          AND fmus.geometry && ST_Transform(ST_TileEnvelope(:z, :x, :y), 4326)
          #{operator_condition}
      ) AS tile
      WHERE tile.mvtgeometry IS NOT NULL
    SQL

    tile = ActiveRecord::Base.connection.execute ActiveRecord::Base.sanitize_sql([query, {z: z, x: x, y: y, operator_id: operator_id, tolerance: 360.0 / (2**z) / 4096}])
    ActiveRecord::Base.connection.unescape_bytea tile.getvalue(0, 0)
  end
end

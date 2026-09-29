class ProtectedAreaVectorTile
  def self.fetch(param_x, param_y, param_z)
    begin
      x, y, z = Integer(param_x), Integer(param_y), Integer(param_z)
    rescue ArgumentError, TypeError
      return nil
    end
    return nil unless z.between?(0, 30)

    query = <<~SQL
      SELECT ST_AsMVT(tile.*, 'layer0', 4096, 'mvtgeometry', 'id') AS tile
      FROM (
        SELECT pa.id,
               json_build_object('name', pa.name) AS properties,
               ST_AsMVTGeom(ST_Transform(ST_Simplify(pa.geometry, :tolerance, true), 3857), ST_TileEnvelope(:z, :x, :y), 4096, 256, true) AS mvtgeometry
        FROM protected_areas pa
        WHERE pa.geometry && ST_Transform(ST_TileEnvelope(:z, :x, :y), 4326)
      ) AS tile
      WHERE tile.mvtgeometry IS NOT NULL
    SQL

    tile = ActiveRecord::Base.connection.execute ActiveRecord::Base.sanitize_sql([query, {z: z, x: x, y: y, tolerance: 360.0 / (2**z) / 4096}])
    ActiveRecord::Base.connection.unescape_bytea tile.getvalue(0, 0)
  end
end

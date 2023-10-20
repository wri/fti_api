class ProtectedArea < ApplicationRecord
  belongs_to :country

  validates :wdpa_pid, presence: true
  validates :name, presence: true
  validates :geojson, presence: true

  after_save :update_geometry, if: :saved_change_to_geojson?

  def bbox
    bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(geometry)
    [bbox.min_x, bbox.min_y, bbox.max_x, bbox.max_y]
  end

  class << self
    # Returns a vector tile for the X,Y,Z provided
    def vector_tiles(param_z, param_x, param_y)
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

  private

  def update_geometry
    query = <<~SQL
      update protected_areas
      set geometry = ST_GeomFromGeoJSON(geojson)
      where protected_areas.id = :protected_area_id
    SQL
    ActiveRecord::Base.connection.update(ProtectedArea.sanitize_sql_for_assignment([query, protected_area_id: id]))
  end
end

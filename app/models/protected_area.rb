class ProtectedArea < ApplicationRecord
  belongs_to :country

  validates :wdpa_pid, presence: true
  validates :name, presence: true
  validates :geojson, presence: true
  validates :geojson, geojson: true

  after_save :update_geometry, if: :saved_change_to_geojson?

  def geojson=(value)
    geojson = case value
    when String
      ActiveSupport::JSON.decode(value)
    when Hash
      value.with_indifferent_access
    else
      value
    end
    if geojson.present? && geojson["type"] != "Feature"
      geojson = {
        type: "Feature",
        geometry: geojson
      }
    end
    super(geojson)
  end

  def bbox
    bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(geometry)
    [bbox.min_x, bbox.min_y, bbox.max_x, bbox.max_y]
  end

  private

  def update_geometry
    query = <<~SQL
      update protected_areas
      set geometry = ST_GeomFromGeoJSON(geojson -> 'geometry')
      where protected_areas.id = :protected_area_id
    SQL
    ActiveRecord::Base.connection.update(ProtectedArea.sanitize_sql_for_assignment([query, protected_area_id: id]))
  end
end

class ProtectedArea < ApplicationRecord
  include EsriShapefileUpload

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
    return nil if geometry.nil?

    bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(geometry)
    [bbox.min_x, bbox.min_y, bbox.max_x, bbox.max_y]
  end

  private

  def update_geometry
    self.class.unscoped.where(id: id).update_all("geometry = ST_GeomFromGeoJSON(geojson -> 'geometry')")
  end
end

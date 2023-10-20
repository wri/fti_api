class ProtectedArea < ApplicationRecord
  belongs_to :country

  validates :wdpa_pid, presence: true
  validates :name, presence: true
  validates :geojson, presence: true

  after_save :update_geometry, if: :saved_change_to_geojson?

  def bbox
    RGeo::Cartesian::BoundingBox.create_from_geometry(geometry)
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

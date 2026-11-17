# frozen_string_literal: true

# == Schema Information
#
# Table name: fmu_geometries
#
#  id         :bigint           not null, primary key
#  fmu_id     :integer          not null
#  geojson    :jsonb
#  geometry   :geometry         geometry, 0
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class FmuGeometry < ApplicationRecord
  has_paper_trail skip: %i[geometry]

  belongs_to :fmu, -> { with_deleted }, inverse_of: :fmu_geometry, touch: true

  after_create :update_geometry, if: :geojson
  after_update :update_geometry, if: :saved_change_to_geojson?

  def properties
    geojson["properties"]
  end

  def centroid
    RGeo::GeoJSON.decode(geojson["properties"]["centroid"])
  rescue
    nil
  end

  def bbox
    return nil if geometry.nil?

    bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(geometry)
    [bbox.min_x, bbox.min_y, bbox.max_x, bbox.max_y]
  end

  def update_geometry
    self.class.where(id: id).update_all("geometry = ST_GeomFromGeoJSON(geojson -> 'geometry')")
    update_centroid
  end

  private

  def update_centroid
    self.class.where(id: id).update_all("geojson = jsonb_set(jsonb_set(geojson, '{properties}', COALESCE(geojson -> 'properties', '{}'), true), '{properties,centroid}', ST_AsGeoJSON(st_centroid(geometry))::jsonb, true)")
  end
end

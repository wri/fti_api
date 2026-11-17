# frozen_string_literal: true

# == Schema Information
#
# Table name: fmu_geometries
#
#  id         :bigint           not null, primary key
#  fmu_id     :integer          not null
#  geojson    :jsonb
#  geometry   :geometry         geometry, 0
#  centroid   :geometry         geometry, 0
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# Only the shape is stored; feature properties are computed at read time by FmuProperties.
class FmuGeometry < ApplicationRecord
  has_paper_trail skip: %i[geometry centroid]

  belongs_to :fmu, -> { with_deleted }, inverse_of: :fmu_geometry, touch: true

  after_create :update_geometry, if: :geojson
  after_update :update_geometry, if: :saved_change_to_geojson?

  def self.normalize_geojson(value)
    value = JSON.parse(value) if value.is_a?(String)
    return value unless value.is_a?(Hash)

    value = value.deep_stringify_keys
    return value unless value["type"] == "Feature"

    {"type" => "Feature", "geometry" => value["geometry"], "properties" => {}}
  rescue JSON::ParserError
    value
  end

  def geojson=(value)
    super(self.class.normalize_geojson(value))
  end

  def bbox
    return nil if geometry.nil?

    bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(geometry)
    [bbox.min_x, bbox.min_y, bbox.max_x, bbox.max_y]
  end

  def update_geometry
    self.class.where(id: id).update_all(
      "geometry = ST_GeomFromGeoJSON(geojson -> 'geometry'), centroid = ST_Centroid(ST_GeomFromGeoJSON(geojson -> 'geometry'))"
    )
    computed = self.class.select(:geometry, :centroid).find(id)
    self.geometry = computed.geometry
    self.centroid = computed.centroid
    clear_attribute_changes(%w[geometry centroid])
  end
end

# frozen_string_literal: true

# == Schema Information
#
# Table name: fmu_geometries
#
#  id         :bigint           not null, primary key
#  fmu_id     :integer          not null
#  geojson    :jsonb
#  geometry   :geometry         geometry, 0
#  centroid          :geometry         geometry, 0
#  source_properties :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

# Only the shape is stored in geojson; feature properties are computed at read time by FmuProperties.
# Attributes that came with an imported shape are kept apart in source_properties.
class FmuGeometry < ApplicationRecord
  DERIVED_PROPERTY_KEYS = (FmuProperties::KEYS + %w[centroid]).freeze

  has_paper_trail skip: %i[geometry centroid source_properties]

  belongs_to :fmu, -> { with_deleted }, inverse_of: :fmu_geometry, touch: true

  after_create :update_geometry, if: :geojson
  after_update :update_geometry, if: :saved_change_to_geojson?

  def self.parse_geojson(value)
    value = JSON.parse(value) if value.is_a?(String)
    value.is_a?(Hash) ? value.deep_stringify_keys : value
  rescue JSON::ParserError
    value
  end

  def self.normalize_geojson(value)
    value = parse_geojson(value)
    return value unless feature?(value)

    {"type" => "Feature", "geometry" => value["geometry"], "properties" => {}}
  end

  def self.feature?(value) = value.is_a?(Hash) && value["type"] == "Feature"

  def geojson=(value)
    value = self.class.parse_geojson(value)
    normalized = self.class.normalize_geojson(value)
    assign_source_properties(value, shape_changed: normalized != geojson)
    super(normalized)
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

  private

  # a re-assigned shape without attributes keeps the ones it was imported with; a new shape replaces them
  def assign_source_properties(value, shape_changed:)
    imported = (value["properties"].except(*DERIVED_PROPERTY_KEYS) if self.class.feature?(value) && value["properties"].is_a?(Hash))
    self.source_properties = imported.presence if imported.present? || shape_changed
  end
end

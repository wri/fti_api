# frozen_string_literal: true

# == Schema Information
#
# Table name: fmus
#
#  id                   :integer          not null, primary key
#  country_id           :integer
#  geojson              :jsonb
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  certification_fsc    :boolean          default(FALSE), not null
#  certification_pefc   :boolean          default(FALSE), not null
#  certification_olb    :boolean          default(FALSE), not null
#  certification_pafc   :boolean          default(FALSE), not null
#  certification_fsc_cw :boolean          default(FALSE), not null
#  certification_tlv    :boolean          default(FALSE), not null
#  forest_type          :integer          default("fmu"), not null
#  geometry             :geometry         geometry, 0
#  deleted_at           :datetime
#  certification_ls     :boolean          default(FALSE), not null
#  name                 :string           not null
#

class Fmu < ApplicationRecord
  has_paper_trail
  acts_as_paranoid

  include EsriShapefileUpload
  include ValidationHelper

  enum forest_type: ForestType::TYPES_WITH_CODE

  belongs_to :country, inverse_of: :fmus
  has_many :observations, inverse_of: :fmu, dependent: :destroy
  has_many :active_observations, -> { active }, class_name: "Observation", inverse_of: :fmu

  has_many :fmu_operators, inverse_of: :fmu, dependent: :destroy
  has_many :operators, through: :fmu_operators
  has_one :fmu_operator, -> { where(current: true) }, inverse_of: :fmu
  has_one :operator, through: :fmu_operator

  has_many :operator_document_fmus, dependent: :destroy

  accepts_nested_attributes_for :operators
  accepts_nested_attributes_for :fmu_operator, reject_if: proc { |attributes| attributes["operator_id"].blank? }

  before_validation :update_geojson_properties

  validates :name, presence: true
  validates :forest_type, presence: true
  validates :geojson, geojson: true, if: :geojson_changed?

  after_save :update_geometry, if: :saved_change_to_geojson?

  # TODO Redo all of those
  scope :filter_by_countries, ->(country_ids) { where(country_id: country_ids.split(",")) }
  scope :filter_by_operators, ->(operator_ids) { joins(:fmu_operators).where(fmu_operators: {current: true, operator_id: operator_ids.split(",")}) }
  # this could also be done like: "id not in ( select fmu_id from fmu_operators where \"current\" = true)"
  # but it might break the method chaining
  scope :filter_by_free, -> { where.not(id: FmuOperator.where(current: true).select(:fmu_id)).group(:id) }
  # TODO remve the filter by free. This needs to be tested
  scope :filter_by_free_aa, -> { where(" fmus.id not in (select fmu_id from fmu_operators where current = true)") }
  scope :current, -> { joins(:fmu_operators).where(fmu_operators: {current: true}) }
  scope :filter_by_forest_type, ->(forest_type) { where(forest_type: forest_type) }
  scope :discriminate_by_forest_type, ->(forest_type) { where.not(forest_type: forest_type) }
  scope :by_name_asc, -> { order(name: :asc) }

  class << self
    def fetch_all(options)
      country_ids = options["country_ids"] if options.present? && options["country_ids"].present? && ValidationHelper.ids?(options["country_ids"])
      operator_ids = options["operator_ids"] if options.present? && options["operator_ids"].present? && ValidationHelper.ids?(options["operator_ids"])
      free = options.present? && options["free"] == "true"

      fmus = includes([:country, :operator])
      fmus = fmus.filter_by_countries(country_ids) if country_ids.present?
      fmus = fmus.filter_by_operators(operator_ids) if operator_ids.present?
      fmus = fmus.filter_by_free if free
      fmus
    end
  end

  def update_geojson_properties
    return if geojson.blank?

    fmu_type_label = begin
      ForestType::TYPES[forest_type.to_sym][:geojson_label]
    rescue
      ""
    end
    geojson["properties"] = (geojson["properties"] || {}).merge({
      "id" => id,
      "fmu_name" => name,
      "iso3_fmu" => country&.iso,
      "company_na" => operator&.name,
      "operator_id" => operator&.id,
      "certification_fsc" => certification_fsc,
      "certification_pefc" => certification_pefc,
      "certification_olb" => certification_olb,
      "certification_pafc" => certification_pafc,
      "certification_fsc_cw" => certification_fsc_cw,
      "certification_tlv" => certification_tlv,
      "certification_ls" => certification_ls,
      "observations" => active_observations.reload.uniq.count,
      "forest_type" => forest_type,
      "fmu_type_label" => fmu_type_label # old one deprecated, to be removed in the future
    })
  end

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

  def cache_key
    super + "-" + Globalize.locale.to_s
  end

  # Methods for Active Admin

  ransacker :operator,
    formatter: proc { |operator_ids|
      matches = Fmu.filter_by_operators(operator_ids).map(&:id)
      matches.any? ? matches : nil
    } do |parent|
    parent.table[:id]
  end

  def update_geometry
    self.class.unscoped.where(id: id).update_all("geometry = ST_GeomFromGeoJSON(geojson -> 'geometry')")
    update_centroid
  end

  def update_centroid
    self.class.unscoped.where(id: id).update_all("geojson = jsonb_set(geojson, '{properties,centroid}', ST_AsGeoJSON(st_centroid(geometry))::jsonb, true)")
  end
end

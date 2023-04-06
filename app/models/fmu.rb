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
#  certification_fsc    :boolean          default(FALSE)
#  certification_pefc   :boolean          default(FALSE)
#  certification_olb    :boolean          default(FALSE)
#  certification_pafc   :boolean          default(FALSE)
#  certification_fsc_cw :boolean          default(FALSE)
#  certification_tlv    :boolean          default(FALSE)
#  forest_type          :integer          default("fmu"), not null
#  geometry             :geometry         geometry, 0
#  deleted_at           :datetime
#  certification_ls     :boolean          default(FALSE)
#  name                 :string
#  deleted_at           :datetime
#

class Fmu < ApplicationRecord
  has_paper_trail
  acts_as_paranoid

  include ValidationHelper
  include Translatable
  translates :name, paranoia: true, touch: true, versioning: :paper_trail

  attr_reader :esri_shapefiles_zip

  active_admin_translates :name do
    validates_presence_of :name
  end

  enum forest_type: ForestType::TYPES_WITH_CODE

  belongs_to :country, inverse_of: :fmus
  has_many :observations, inverse_of: :fmu, dependent: :destroy
  has_many :active_observations, -> { active }, class_name: "Observation"

  has_many :fmu_operators, inverse_of: :fmu, dependent: :destroy
  has_many :operators, through: :fmu_operators
  has_one :fmu_operator, -> { where(current: true) }
  has_one :operator, through: :fmu_operator

  has_many :operator_document_fmus, dependent: :destroy

  accepts_nested_attributes_for :operators
  accepts_nested_attributes_for :fmu_operator, reject_if: proc { |attributes| attributes["operator_id"].blank? }

  before_validation :update_geojson_properties

  validates :country_id, presence: true
  validates :name, presence: true
  validates :forest_type, presence: true
  validate :geojson_correctness, if: :geojson_changed?

  after_save :update_geometry, if: :saved_change_to_geojson?

  default_scope { includes(:translations) }

  # TODO Redo all of those
  scope :filter_by_countries, ->(country_ids) { where(country_id: country_ids.split(",")) }
  scope :filter_by_operators, ->(operator_ids) { joins(:fmu_operators).where(fmu_operators: {current: true, operator_id: operator_ids.split(",")}) }
  # this could also be done like: "id not in ( select fmu_id from fmu_operators where \"current\" = true)"
  # but it might break the method chaining
  scope :filter_by_free, -> { where.not(id: FmuOperator.where(current: true).pluck(:fmu_id)).group(:id) }
  # TODO remve the filter by free. This needs to be tested
  scope :filter_by_free_aa, -> { where(" fmus.id not in (select fmu_id from fmu_operators where current = true)") }
  scope :current, -> { joins(:fmu_operators).where(fmu_operators: {current: true}) }
  scope :filter_by_forest_type, ->(forest_type) { where(forest_type: forest_type) }
  scope :discriminate_by_forest_type, ->(forest_type) { where.not(forest_type: forest_type) }
  scope :by_name_asc, -> { with_translations(I18n.locale).order("fmu_translations.name") }

  ransacker(:name) { Arel.sql("fmu_translations.name") } # for nested_select in observation form

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

    # Returns a vector tile for the X,Y,Z provided
    def vector_tiles(param_z, param_x, param_y, operator_id)
      begin
        x, y, z = Integer(param_x), Integer(param_y), Integer(param_z)
      rescue ArgumentError, TypeError
        return nil
      end

      operator_condition = operator_id.present? ? sanitize_sql(["AND operator_id=?", operator_id]) : ""

      query = <<~SQL
        SELECT ST_ASMVT(tile.*, 'layer0', 4096, 'mvtgeometry', 'id') as tile
          FROM (
            SELECT id, geojson -> 'properties' as properties, ST_AsMVTGeom(the_geom_webmercator, ST_TileEnvelope(#{z},#{x},#{y}), 4096, 256, true) AS mvtgeometry
            FROM (
              SELECT fmus.*, st_transform(geometry, 3857) as the_geom_webmercator
              FROM fmus
                LEFT JOIN fmu_operators fo on fo.fmu_id = fmus.id and fo.current = true
              WHERE fmus.deleted_at IS NULL #{operator_condition}
            ) as data
            WHERE ST_AsMVTGeom(the_geom_webmercator, ST_TileEnvelope(#{z},#{x},#{y}),4096,0,true) IS NOT NULL
          ) AS tile;
      SQL

      tile = ActiveRecord::Base.connection.execute query
      ActiveRecord::Base.connection.unescape_bytea tile.getvalue(0, 0)
    end
  end

  def esri_shapefiles_zip=(esri_shapefiles_zip)
    FileDataImport::Parser::Zip.new(esri_shapefiles_zip.path).foreach_with_line do |attributes, index|
      # takes only the first feature from the Esri shapefile.
      self.geojson = attributes[:geojson].slice("type", "geometry").merge("properties" => {})
      break
    end

    @esri_shapefiles_zip = esri_shapefiles_zip
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

  def bbox
    query = <<~SQL
      SELECT st_astext(st_envelope(geometry))
      FROM fmus
      where id = #{id}
    SQL
    envelope =
      ActiveRecord::Base.connection.execute(query)[0]["st_astext"][9..-3]
        .split(/ |,/).map(&:to_f).each_slice(2).to_a
    [envelope[0], envelope[2]]
  rescue
    nil
  end

  def self.file_upload(esri_shapefiles_zip)
    PaperTrail.request.disable_model(Fmu)
    PaperTrail.request.disable_model(Fmu::Translation)
    tmp_fmu = Fmu.new(name: "Test #{Time.now.to_i}", country_id: Country.first.id)
    FileDataImport::Parser::Zip.new(esri_shapefiles_zip.path).foreach_with_line do |attributes, _index|
      tmp_fmu.geojson = attributes[:geojson].slice("type", "geometry").merge("properties" => {})
      break
    end
    tmp_fmu.save(validate: false)

    response = {
      geojson: tmp_fmu.geojson,
      bbox: tmp_fmu.bbox
    }
    tmp_fmu.really_destroy!
    PaperTrail.request.enable_model(Fmu)
    PaperTrail.request.enable_model(Fmu::Translation)
    response
  rescue => e
    PaperTrail.request.enable_model(Fmu)
    PaperTrail.request.enable_model(Fmu::Translation)
    {errors: e.message}
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

  private

  def update_geometry
    query = <<~SQL
      update fmus
        set geometry = ST_GeomFromGeoJSON(geojson -> 'geometry')
      where fmus.id = :fmu_id
    SQL
    ActiveRecord::Base.connection.update(Fmu.sanitize_sql_for_assignment([query, fmu_id: id]))
    update_centroid
  end

  def update_centroid
    query = <<~SQL
      update fmus
        set geojson = jsonb_set(geojson, '{properties,centroid}', ST_AsGeoJSON(st_centroid(geometry))::jsonb, true)
      where fmus.id = :fmu_id;
    SQL
    ActiveRecord::Base.connection.update(Fmu.sanitize_sql_for_assignment([query, fmu_id: id]))
  end

  def geojson_correctness
    return if geojson.blank?

    temp_geometry = RGeo::GeoJSON.decode geojson
    bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(temp_geometry.geometry)
    validate_bbox bbox
  rescue RGeo::Error::InvalidGeometry
    errors.add(:geojson, "Failed linear ring test")
  rescue => e
    errors.add(:geojson, "Error: #{e.message}")
  end

  def validate_bbox(bbox)
    return if bbox.max_x <= 180 && bbox.min_x >= -180 && bbox.max_y <= 90 && bbox.min_y >= -90

    errors.add(:geojson, "The FMU's bbox is bigger than the globe. Please make sure your projection is 4326")
  end
end

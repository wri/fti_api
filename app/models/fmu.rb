# frozen_string_literal: true

# == Schema Information
#
# Table name: fmus
#
#  id                   :integer          not null, primary key
#  country_id           :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  certification_fsc    :boolean          default(FALSE), not null
#  certification_pefc   :boolean          default(FALSE), not null
#  certification_olb    :boolean          default(FALSE), not null
#  certification_pafc   :boolean          default(FALSE), not null
#  certification_fsc_cw :boolean          default(FALSE), not null
#  certification_tlv    :boolean          default(FALSE), not null
#  forest_type          :integer          default("fmu"), not null
#  deleted_at           :datetime
#  certification_ls     :boolean          default(FALSE), not null
#  name                 :string           not null
#  certification_pbn    :boolean          default(FALSE), not null
#

class Fmu < ApplicationRecord
  has_paper_trail
  acts_as_paranoid

  include EsriShapefileUpload
  include ValidationHelper

  enum :forest_type, ForestType::TYPES_WITH_CODE

  belongs_to :country, inverse_of: :fmus
  # declared before the operator associations: their save callbacks reload the fmu, dropping an unsaved geometry
  # no dependent: :destroy - soft-deleted fmus keep their geometry, hard deletes cascade in the DB
  has_one :fmu_geometry, autosave: true, inverse_of: :fmu
  has_many :observations, inverse_of: :fmu, dependent: :destroy
  has_many :active_observations, -> { active }, class_name: "Observation", inverse_of: :fmu

  has_many :fmu_operators, inverse_of: :fmu, dependent: :destroy
  has_many :operators, through: :fmu_operators
  has_one :fmu_operator, -> { where(current: true) }, inverse_of: :fmu
  has_one :operator, through: :fmu_operator

  has_many :operator_document_fmus, dependent: :destroy

  accepts_nested_attributes_for :operators
  accepts_nested_attributes_for :fmu_operator, reject_if: proc { |attributes| attributes["operator_id"].blank? }

  validates :name, presence: true
  validates :forest_type, presence: true
  validates :geojson, geojson: true, if: :geojson_changed?

  delegate :geometry, :bbox, :centroid, to: :fmu_geometry, allow_nil: true

  after_update :sync_operator_documents, if: :saved_change_to_forest_type?

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

      fmus = includes([:country, :operator, :fmu_geometry])
      fmus = fmus.filter_by_countries(country_ids) if country_ids.present?
      fmus = fmus.filter_by_operators(operator_ids) if operator_ids.present?
      fmus = fmus.filter_by_free if free
      fmus
    end
  end

  def geojson
    fmu_geometry&.geojson
  end

  def geojson=(value)
    return if value.nil? && fmu_geometry.nil?

    (fmu_geometry || build_fmu_geometry).geojson = value
  end

  def geojson_changed?
    fmu_geometry.present? && fmu_geometry.geojson_changed?
  end

  def properties
    FmuProperties.for([id])[id]
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

  def sync_operator_documents
    fmu_operator&.update_documents_list
  end
end

# frozen_string_literal: true
# == Schema Information
#
# Table name: fmus
#
#  id                 :integer          not null, primary key
#  country_id         :integer
#  geojson            :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  certification_fsc  :boolean          default(FALSE)
#  certification_pefc :boolean          default(FALSE)
#  certification_olb  :boolean          default(FALSE)
#  certification_vlc  :boolean
#  certification_vlo  :boolean
#  certification_tltv :boolean
#

class Fmu < ApplicationRecord
  include ValidationHelper
  include Translatable
  translates :name, touch: true

  active_admin_translates :name do
    validates_presence_of :name
  end

  belongs_to :country, inverse_of: :fmus
  has_many :observations, inverse_of: :fmu

  has_many :fmu_operators, inverse_of: :fmu
  has_many :operators, through: :fmu_operators
  has_one :fmu_operator, ->{ where(current: true) }
  has_one :operator, through: :fmu_operator


  accepts_nested_attributes_for :operators

  validates :country_id, presence: true
  validates :name, presence: true

  before_save :update_geojson

  default_scope { includes(:translations) }

  # TODO Redo all of those
  scope :filter_by_countries,      ->(country_ids)  { where(country_id: country_ids.split(',')) }
  scope :filter_by_operators,      ->(operator_ids) { joins(:fmu_operators).where(fmu_operators: { current: true, operator_id: operator_ids.split(',') }) }
  # this could also be done like: "id not in ( select fmu_id from fmu_operators where \"current\" = true)"
  # but it might break the method chaining
  scope :filter_by_free,           ->()             { where.not(id: FmuOperator.where(current: :true).pluck(:fmu_id)).group(:id) }
  scope :with_certification_fsc,   ->()             { where certification_fsc: true }
  scope :with_certification_pefc,  ->()             { where certification_pefc: true }
  scope :with_certification_olb,   ->()             { where certification_olb: true }
  scope :with_certification_vlc,   ->()             { where certification_vlc: true }
  scope :with_certification_vlo,   ->()             { where certification_vlo: true }
  scope :with_certification_tltv,  ->()             { where certification_tltv: true }
  scope :current,                  ->()             { joins(:fmu_operators).where(fmu_operators: { current: true }) }

  class << self
    def fetch_all(options)
      country_ids  = options['country_ids'] if options.present? && options['country_ids'].present? && ValidationHelper.ids?(options['country_ids'])
      operator_ids  = options['operator_ids'] if options.present? && options['operator_ids'].present? && ValidationHelper.ids?(options['operator_ids'])
      free = options.present? && options['free'] == 'true'

      fmus = includes([:country, :operator])
      fmus = fmus.filter_by_countries(country_ids) if country_ids.present?
      fmus = fmus.filter_by_operators(operator_ids) if operator_ids.present?
      fmus = fmus.filter_by_free if free
      fmus
    end
  end

  def update_geojson
    temp_geojson = self.geojson
    return if temp_geojson.blank?
    temp_geojson['properties']['fmu_name'] = self.name
    temp_geojson['properties']['company_na'] = self.operator.name if self.operator.present?
    temp_geojson['properties']['operator_id'] = self.operator.id if self.operator.present?
    temp_geojson['properties']['certification_fsc'] = self.certification_fsc
    temp_geojson['properties']['certification_pefc'] = self.certification_pefc
    temp_geojson['properties']['certification_olb'] = self.certification_olb
    temp_geojson['properties']['certification_vlc'] = self.certification_vlc
    temp_geojson['properties']['certification_vlo'] = self.certification_vlo
    temp_geojson['properties']['certification_tltv'] = self.certification_tltv

    self.geojson = temp_geojson
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end

  # Methods for Active Admin

  ransacker :operator,
            formatter: proc { |operator_ids|
              matches = Fmu.filter_by_operators(operator_ids).map(&:id)
              matches.any? ? matches : nil
            } do |parent|
    parent.table[:id]
  end
end

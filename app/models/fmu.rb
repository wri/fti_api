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
#

class Fmu < ApplicationRecord
  include ValidationHelper
  translates :name, touch: true

  active_admin_translates :name do
    validates_presence_of :name
  end

  belongs_to :country, inverse_of: :fmus
  belongs_to :operator, inverse_of: :fmus
  has_many :observations, inverse_of: :fmu

  validates :country_id, presence: true
  validates :name, presence: true

  before_save :update_geojson

  default_scope { includes(:translations) }

  scope :filter_by_countries,      ->(country_ids)  { where(country_id: country_ids.split(',')) }
  scope :filter_by_operators,      ->(operator_ids) { where(operator_id: operator_ids.split(',')) }
  scope :filter_by_free,           ->()             { where operator_id: nil}
  scope :with_certification_fsc,   ->()             { where certification_fsc: true }
  scope :with_certification_pefc,  ->()             { where certification_pefc: true }
  scope :with_certification_olb,   ->()             { where certification_olb: true }
  scope :current,                  ->()             { }

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
    return unless temp_geojson.present?
    temp_geojson['properties']['fmu_name'] = self.name
    temp_geojson['properties']['company_na'] = self.operator.name if self.operator.present?
    temp_geojson['properties']['operator_id'] = self.operator_id if self.operator_id.present?
    temp_geojson['properties']['certification_fsc'] = self.certification_fsc
    temp_geojson['properties']['certification_pefc'] = self.certification_pefc
    temp_geojson['properties']['certification_olb'] = self.certification_olb

    self.geojson = temp_geojson
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end
end

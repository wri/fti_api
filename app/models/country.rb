# frozen_string_literal: true

# == Schema Information
#
# Table name: countries
#
#  id               :integer          not null, primary key
#  iso              :string
#  region_iso       :string
#  country_centroid :jsonb
#  region_centroid  :jsonb
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  is_active        :boolean          default(FALSE), not null
#  overview         :text
#  vpa_overview     :text
#  name             :string
#  region_name      :string
#

class Country < ApplicationRecord
  include Translatable
  translates :name, :region_name, :overview, :vpa_overview, touch: true

  active_admin_translates :name, :region_name, :overview, :vpa_overview do
    validates :name, presence: true
  end

  has_many :users, inverse_of: :country
  has_many :observations, inverse_of: :country
  has_and_belongs_to_many :observers
  has_many :governments, inverse_of: :country
  has_many :operators, inverse_of: :country
  has_many :fmus, inverse_of: :country
  has_many :laws, inverse_of: :country

  has_many :species_countries
  has_many :species, through: :species_countries
  has_many :required_operator_documents
  has_many :required_gov_documents
  has_many :gov_documents

  has_many :country_links, inverse_of: :country
  has_many :country_vpas, inverse_of: :country

  has_and_belongs_to_many :responsible_admins, join_table: "country_responsible_admins", class_name: "User", dependent: :destroy

  validates :name, :iso, presence: true, uniqueness: {case_sensitive: false}

  before_save :set_active

  scope :by_name_asc, -> { with_translations(I18n.locale).order(:name) }
  scope :with_observations, ->(scope = Observation.all) { where(id: scope.select(:country_id)) }
  scope :with_at_least_one_report, -> { where(id: ObservationReport.joins(:observations).select("observations.country_id").distinct.select("observations.country_id")) }
  scope :by_status, ->(status) { where(is_active: status) }
  scope :active, -> { where(is_active: true) }

  def cache_key
    super + "-" + Globalize.locale.to_s
  end

  def forest_types
    fmus.map { |fmu| fmu.forest_type }.compact.uniq
  end

  private

  def set_active
    self.is_active = true unless is_active.in? [true, false]
  end
end

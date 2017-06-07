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
#

class Country < ApplicationRecord
  translates :name, :region_name

  has_many :users,           inverse_of: :country
  has_many :observations,    inverse_of: :country
  has_many :observers,       inverse_of: :country
  has_many :annex_operators, inverse_of: :country
  has_many :laws,            inverse_of: :country
  has_many :governments,     inverse_of: :country
  has_many :operators,       inverse_of: :country
  has_many :fmus,            inverse_of: :country

  has_many :species_countries
  has_many :species, through: :species_countries

  validates :name, :iso, presence: true, uniqueness: { case_sensitive: false }

  before_save :set_active

  scope :by_name_asc, -> {
    includes(:translations).with_translations(I18n.available_locales)
                           .order('country_translations.name ASC')
  }

  scope :by_status, ->(status) { where(is_active: status) }

  default_scope do
    includes(:translations)
  end

  class << self
    def fetch_all(options)
      by_status = options['is_active'] if options.present? && options['is_active'].in?(['true', 'false'])

      countries = all
      countries = countries.by_status(by_status) if by_status.present?
      countries
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end

  private

  def set_active
    is_active = true unless is_active == true || is_active == false
  end
end

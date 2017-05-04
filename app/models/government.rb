# frozen_string_literal: true

# == Schema Information
#
# Table name: governments
#
#  id         :integer          not null, primary key
#  country_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Government < ApplicationRecord
  translates :government_entity, :details

  belongs_to :country, inverse_of: :governments, optional: true

  has_many :observations, inverse_of: :government

  validates :government_entity, presence: true

  scope :by_entity_asc, -> {
    includes(:translations).with_translations(I18n.available_locales)
        .order('government_translations.government_entity ASC')
  }

  scope :filter_by_country, ->(country_id) { where(country_id: country_id) }

  default_scope { includes(:translations) }

  class << self
    def fetch_all(options)
      country_id  = options['country'] if options.present? && options['country'].present?

      governments = includes(:country)
      governments = governments.filter_by_country(country_id) if country_id.present?
      governments
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end
end

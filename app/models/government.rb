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

  scope :by_country, ->country_id { where('governments.country_id = ?', country_id) }

  default_scope { includes(:translations) }

  class << self
    def fetch_all(options)
      governments = by_entity_asc
      governments
    end

    def entity_select(options)
      country_id = options[:country_id] if options[:country_id].present?
      by_country(country_id).by_entity_asc.map { |c| [c.government_entity, c.id] }
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end
end

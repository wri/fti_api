# frozen_string_literal: true

# == Schema Information
#
# Table name: laws
#
#  id            :integer          not null, primary key
#  country_id    :integer
#  vpa_indicator :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Law < ApplicationRecord
  translates :legal_reference, :legal_penalty

  belongs_to :country, inverse_of: :laws

  has_many :annex_operator_laws
  has_many :annex_operators, through: :annex_operator_laws

  validates :legal_reference, presence: true

  scope :by_legal_reference_asc, -> {
    includes(:translations).with_translations(I18n.available_locales)
                           .order('law_translations.legal_reference ASC')
  }

  scope :filter_by_country, ->(country_id) { where(country_id: country_id) }

  default_scope do
    includes(:translations)
  end

  class << self
    def fetch_all(options)
      country_id  = options['country'] if options.present? && options['country'].present?

      laws = includes(:country)
      laws = laws.filter_by_country(country_id) if country_id.present?
      laws
    end

    def law_select
      by_legal_reference_asc.map { |c| [c.legal_reference, c.id] }
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end
end

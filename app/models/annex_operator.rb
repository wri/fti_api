# frozen_string_literal: true

# == Schema Information
#
# Table name: annex_operators
#
#  id         :integer          not null, primary key
#  country_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AnnexOperator < ApplicationRecord
  translates :illegality, :details

  belongs_to :country, inverse_of: :annex_operators

  has_many :severities,   as: :severable
  has_many :categorings,  as: :categorizable
  has_many :categories,   through: :categorings
  has_many :comments,     as: :commentable
  has_many :observations, inverse_of: :annex_operator
  has_many :annex_operator_laws
  has_many :laws, through: :annex_operator_laws

  accepts_nested_attributes_for :severities,  allow_destroy: true
  accepts_nested_attributes_for :categorings, allow_destroy: true
  accepts_nested_attributes_for :laws,        allow_destroy: true

  validates :illegality, presence: true

  scope :by_illegality_asc, -> {
    includes(:translations).with_translations(I18n.available_locales)
                           .order('annex_operator_translations.illegality ASC')
  }

  scope :filter_by_country, ->(country_id) { where(country_id: country_id) }

  default_scope do
    includes(:translations)
  end

  class << self
    def fetch_all(options)
      country_id  = options['country'] if options.present? && options['country'].present?

      annex_operators = includes({ severities: :translations },
                                 { categories: :translations },
                                 { laws: :translations },
                                 :comments, :country)

      annex_operators = annex_operators.filter_by_country(country_id) if country_id.present?
      annex_operators
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end
end

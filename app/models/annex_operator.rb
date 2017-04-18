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

  scope :by_country, ->country_id { where('annex_operators.country_id = ?', country_id) }

  default_scope do
    includes(:translations, { severities: :translations },
                            { categories: :translations },
                            { laws: :translations },
                            :comments, :country)
  end

  class << self
    def fetch_all(options)
      annex_operators = all
      annex_operators
    end

    def illegality_select(options=nil)
      country_id = options[:country_id] if options.present? && options[:country_id].present?
      illegalities = all
      illegalities = illegalities.by_country(country_id) if country_id.present?
      illegalities.by_illegality_asc.map { |il| [il.illegality, il.id] }
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end
end

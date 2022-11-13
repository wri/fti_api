# frozen_string_literal: true

# == Schema Information
#
# Table name: laws
#
#  id                 :integer          not null, primary key
#  written_infraction :text
#  infraction         :text
#  sanctions          :text
#  min_fine           :integer
#  max_fine           :integer
#  penal_servitude    :string
#  other_penalties    :text
#  apv                :text
#  subcategory_id     :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  country_id         :integer
#  currency           :string
#

class Law < ApplicationRecord
  belongs_to :subcategory, inverse_of: :laws
  belongs_to :country, inverse_of: :laws
  has_many   :observations, inverse_of: :law

  validates :min_fine, numericality: { greater_than_or_equal_to: 0 }, if: :min_fine?
  validates :max_fine, numericality: { greater_than_or_equal_to: 0 }, if: :max_fine?

  scope :by_country_subcategory, ->(observation) { where(country_id: observation.country_id, subcategory_id: observation.subcategory_id) }
  scope :with_country_subcategory, ->{
    includes(country: :translations)
      .includes(subcategory: :translations)
      .where("country_translations.locale = ?", I18n.locale)
      .where("subcategory_translations.locale = ?", I18n.locale).order('country_translations.name, subcategory_translations.name')
  }
end

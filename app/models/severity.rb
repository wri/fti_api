# frozen_string_literal: true

# == Schema Information
#
# Table name: severities
#
#  id             :integer          not null, primary key
#  level          :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  subcategory_id :integer
#  details        :text
#

class Severity < ApplicationRecord
  include Translatable

  translates :details, touch: true
  # rubocop:disable Standard/BlockSingleLineBraces
  active_admin_translates :details do; end
  # rubocop:enable Standard/BlockSingleLineBraces

  belongs_to :subcategory, inverse_of: :severities
  has_many :observations, inverse_of: :severity

  def level_details
    "#{level} - #{details}"
  end

  validates :level, presence: true
  validates :level, uniqueness: {scope: :subcategory_id}
  validates :level, numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 3}

  default_scope { includes(:translations) }

  ransacker(:details) { Arel.sql("severity_translations.details") } # for nested_select in observation form

  def cache_key
    super + "-" + Globalize.locale.to_s
  end
end

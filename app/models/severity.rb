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
#

class Severity < ApplicationRecord
  translates :details

  belongs_to :subcategory, inverse_of: :severities
  has_many :observations, inverse_of: :severity

  def level_details
    "#{self.level} - #{self.details}"
  end

  validates_presence_of   :level
  validates_uniqueness_of :level, scope: :subcategory_id

  default_scope { includes(:translations) }

  class << self
    def fetch_all(options)
      severities = by_level_asc
      severities
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end
end

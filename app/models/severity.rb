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
  include Translatable
  translates :details, touch: true

  active_admin_translates :details do; end

  belongs_to :subcategory, inverse_of: :severities
  has_many :observations, inverse_of: :severity

  def level_details
    "#{self.level} - #{self.details}"
  end

  validates_presence_of   :level
  validates_uniqueness_of :level, scope: :subcategory_id

  default_scope { includes(:translations) }

  def cache_key
    super + '-' + Globalize.locale.to_s
  end
end

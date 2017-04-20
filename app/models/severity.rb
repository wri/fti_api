# frozen_string_literal: true

# == Schema Information
#
# Table name: severities
#
#  id             :integer          not null, primary key
#  level          :integer
#  severable_id   :integer          not null
#  severable_type :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Severity < ApplicationRecord
  translates :details

  belongs_to :severable, polymorphic: true
  belongs_to :annex_governance, foreign_key: :severable_id
  belongs_to :annex_operator,   foreign_key: :severable_id

  has_many :observations, inverse_of: :severity

  def level_details
    "#{self.level} - #{self.details}"
  end

  validates_presence_of   :level
  validates_uniqueness_of :level, scope: [:severable_type, :severable_id]

  scope :by_level_asc, -> {
    includes(:translations).order('severities.level ASC')
  }

  default_scope { includes(:translations) }

  class << self
    def fetch_all(options)
      severities = by_level_asc
      severities
    end

    def severity_select(options)
      annex_operator_id   = options[:annex_operator_id]   if options[:annex_operator_id].present?
      annex_governance_id = options[:annex_governance_id] if options[:annex_governance_id].present?
      severable_type      = if options[:annex_operator_id].present?
                              'AnnexOperator'
                            else
                              'AnnexGovernance'
                            end
      annex_id = annex_operator_id || annex_governance_id

      where(severable_id: annex_id, severable_type: severable_type).by_level_asc.map { |c| ["#{c.level} - #{c.details}", c.id] }
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end
end

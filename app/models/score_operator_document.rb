# frozen_string_literal: true

# == Schema Information
#
# Table name: score_operator_documents
#
#  id          :integer          not null, primary key
#  date        :date             not null
#  current     :boolean          default("true"), not null
#  all         :float
#  country     :float
#  fmu         :float
#  operator_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class ScoreOperatorDocument < ApplicationRecord
  include MathHelper

  belongs_to :operator, touch: true
  validates_presence_of :date

  scope :current, -> { where(current: true) }

  # Calculates the scores and if they're different from the current score
  # it creates a new SOD as the current one
  # @note Only operators with fo_id have scores
  # @param [Operator] operator The operator for which to recalculate
  def self.recalculate!(operator)
    return if operator.fa_id.blank?

    current_sod = operator.score_operator_document || ScoreOperatorDocument.new
    current_sod.replace(operator)
  end

  # Builds a SOD for an operator
  # @param [Operator] operator The operator
  # @return [ScoreOperatorDocument] The SOD created
  def self.build(operator)
    sod = ScoreOperatorDocument.new date: Date.today, operator: operator, current: true
    queryBuilder = operator.approved ? RequiredDocumentsQuery : AvailableRequiredDocumentsQuery
    sod.calculate_scores(queryBuilder)
    sod
  end

  # Replaces the current SOD with a new one, if they're different
  # Updates the current SOD so it's not current anymore, and creates a new one
  # If the dates are the same, it just updates the values
  # @param [Operator] operator The operator
  def replace(operator)
    sod = ScoreOperatorDocument.build(operator)
    return if self == sod && persisted?
    return update_values(sod) if date == sod.date && persisted?

    add_new(sod)
  end

  # Calculates the SOD of an operator (all, fmu, and country)
  # @note Only required documents are used for this calculation (current and not deleted ones).
  # We also remove the one whose required_operator_documents have been deleted
  # @param [RequiredDocumentsQuery] queryBuilder the query method to use
  def calculate_scores(queryBuilder)
    self.all = query_divider ValidDocumentsQuery.new.call(operator.operator_documents), queryBuilder.new.call(operator.operator_documents)
    self.fmu = query_divider ValidDocumentsQuery.new.call(operator.operator_document_fmus), queryBuilder.new.call(operator.operator_document_fmus)
    self.country = query_divider ValidDocumentsQuery.new.call(operator.operator_document_countries), queryBuilder.new.call(operator.operator_document_countries)
  end

  protected

  def ==(obj)
    self.all == obj.all && self.fmu == obj.fmu && self.country == obj.country
  end

  private

  # Adds a new SOD and makes marks the old one as not current
  # @param [ScoreOperatorDocument] sod The new sod
  def add_new(sod)
    update!(current: false) if persisted?
    sod.save!
  end

  # Changes the old values of the sod to the new one
  # This should be called when updating the values of the same day
  # @param [ScoreOperatorDocument] sod The SOD with the new values
  def update_values(sod)
    self.all = sod.all
    self.country = sod.country
    self.fmu = sod.fmu
    save!
  end
end


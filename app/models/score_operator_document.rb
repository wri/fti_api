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
  belongs_to :operator
  validates_presence_of :date

  scope :current, -> { where(current: true)}

  # Calculates the scores and if they're different from the current score
  # it creates a new SOD as the current one
  # @note Only operators with fo_id have scores
  # @param [Operator] operator The operator for which to recalculate
  def self.recalculate!(operator)
    return if operator.fa_id.blank?

    current_sod = operator.score_operator_document
    new_sod = ScoreOperatorDocument.build(operator)
    replace_sod(current_sod, new_sod)
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
  # @param [ScoreOperatorDocument] current_sod The current SOD
  # @param [ScoreOperatorDocument] new_sod The new SOD
  def self.replace_sod(current_sod, new_sod)
    return if current_sod == new_sod

    current_sod.update!(current: false)
    new_sod.save!
  end

  protected

  def ==(obj)
    self.all == obj.all && self.fmu == obj.fmu && self.country == obj.country
  end

  private

  # Calculates the SOD of an operator (all, fmu, and country)
  # @note Only required documents are used for this calculation (current and not deleted ones).
  # We also remove the one whose required_operator_documents have been deleted
  # @param [RequiredDocumentsQuery] queryBuilder the query method to use
  def calculate_scores(queryBuilder)
    self.all = queryBuilder.call(operator.operator_documents).count.to_f / ValidDocumentsQuery.call(operator.operator_documents).count.to_f rescue 0
    self.fmu = queryBuilder.call(operator.operator_document_fmu).count.to_f / ValidDocumentsQuery.call(operator.operator_document_fmus).count.to_f rescue 0
    self.country = queryBuilder.call(operator.operator_document_countries).count.to_f / ValidDocumentsQuery.call(operator.operator_document_countries).count.to_f rescue 0
  end
end


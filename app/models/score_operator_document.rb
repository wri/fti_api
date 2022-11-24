# frozen_string_literal: true

# == Schema Information
#
# Table name: score_operator_documents
#
#  id              :integer          not null, primary key
#  date            :date             not null
#  current         :boolean          default(TRUE), not null
#  all             :float
#  country         :float
#  fmu             :float
#  summary_public  :jsonb
#  summary_private :jsonb
#  total           :integer
#  operator_id     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class ScoreOperatorDocument < ApplicationRecord
  belongs_to :operator, touch: true
  validates_presence_of :date
  validates_uniqueness_of :current, scope: :operator_id, if: :current?

  after_commit :refresh_ranking

  scope :current, -> { where(current: true) }
  scope :at_date, ->(date) { where("date <= ?", date) }

  VALUE_ATTRS = %w[all fmu country total summary_public summary_private].freeze

  # Calculates the scores and if they're different from the current score
  # it creates a new SOD as the current one
  # @note Only operators with fo_id have scores
  # @param [Operator] operator The operator for which to recalculate
  def self.recalculate!(operator)
    return if operator.fa_id.blank?

    current_sod = operator.reload_score_operator_document || ScoreOperatorDocument.new
    current_sod.replace(operator)
  end

  # Builds a SOD for an operator
  # @param [Operator] operator The operator
  # @return [ScoreOperatorDocument] The SOD created
  def self.build(operator, docs = nil)
    docs ||= operator.operator_documents
    sod = ScoreOperatorDocument.new date: Date.today, operator: operator, current: true
    calculator = ScoreOperatorPresenter.new(docs)
    sod.all = calculator.all
    sod.fmu = calculator.fmu
    sod.country = calculator.country
    sod.total = calculator.total
    sod.summary_private = calculator.summary_private
    sod.summary_public = calculator.summary_public
    sod
  end

  # Resync the score using operator document history
  def resync!
    docs = OperatorDocumentHistory.from_operator_at_date(operator_id, date)
    new_score = ScoreOperatorDocument.build(operator, docs)
    self.all = new_score.all
    self.fmu = new_score.fmu
    self.country = new_score.country
    self.total = new_score.total
    self.summary_private = new_score.summary_private
    self.summary_public = new_score.summary_public
    save!
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

  def ==(obj)
    return false unless obj.is_a? self.class

    VALUE_ATTRS.reject do |attr|
      read_attribute(attr) == obj.read_attribute(attr)
    end.none?
  end

  private

  def refresh_ranking
    RankingOperatorDocument.refresh_for_country(operator.country)
  end

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
    VALUE_ATTRS.each do |attr|
      write_attribute attr, sod.read_attribute(attr)
    end
    save!
  end
end

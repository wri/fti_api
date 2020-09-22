# == Schema Information
#
# Table name: score_operator_observations
#
#  id            :integer          not null, primary key
#  date          :date             not null
#  current       :boolean          default("true"), not null
#  score         :float
#  obs_per_visit :float
#  operator_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class ScoreOperatorObservation < ApplicationRecord
  belongs_to :operator, touch: true
  validates_presence_of :date

  scope :current, -> { where(current: true) }

  attr_accessor :visits

  def self.recalculate!(operator)
    return if operator.fa_id.blank?

    soo = operator.score_operator_observation || ScoreOperatorObservation.new
    soo.recalculate!(operator)
  end

  def recalculate!(operator)
    new_soo = ScoreOperatorObservation.build(operator)
    replace(new_soo)
  end

  def self.build(operator)
    soo = ScoreOperatorObservation.new operator: operator, date: Date.today, current: true
    soo.count_visits
    return soo if soo.visits.zero?

    soo.calculate
    soo
  end

  def count_visits
    visits_query = observations.select('date(publication_date)').group('date(publication_date)').count
    self.visits = visits_query.keys.count
  end

  def calculate
    self.obs_per_visit = observations.count.to_f / visits
    high = severity_per_visit 3
    medium = severity_per_visit 2
    low = severity_per_visit 1
    unknown = severity_per_visit 0
    self.score = (4 * high + 2 * medium + 2 * unknown + low).to_f / 9
  end

  # Syntactic sugar
  def observations
    operator.observations.unscope(:joins)
  end

  protected

  # Overrides the ==. It's now true when the score and obs_per_visit have the same value
  # @param [ScoreOperatorObservation] obj
  def ==(obj)
    self.score == obj.score && self.obs_per_visit == obj.obs_per_visit
  end

  private

  # Returns the number of observations per visit of a given severity level
  # @param [Integer] level The level of severity
  # @return [Float] The number of observations per visit
  def severity_per_visit(level)
    observations.joins(:severity).where({severities: {level: level}}).count.to_f / visits
  end

  # Replaces the current SOO with the new one if it didn't change
  # @param [ScoreOperatorObservation] soo The new SOO
  def replace(soo)
    return if self == soo && persisted?

    update!(current: false) if present? && persisted?
    soo.save!
  end
end

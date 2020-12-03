# == Schema Information
#
# Table name: global_observation_scores
#
#  id              :integer          not null, primary key
#  date            :date             not null
#  obs_total       :integer
#  rep_total       :integer
#  rep_country     :jsonb
#  rep_monitor     :jsonb
#  obs_country     :jsonb
#  obs_status      :jsonb
#  obs_producer    :jsonb
#  obs_severity    :jsonb
#  obs_category    :jsonb
#  obs_subcategory :jsonb
#  obs_fmu         :jsonb
#  obs_forest_type :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class GlobalObservationScore < ApplicationRecord
  validates_presence_of :date
  validates_uniqueness_of :date

  # Calculates the observation score for a given day
  # @param [Date] date The date for which to calculate
  def self.calculate(date)
    return unless date.is_a? Date

    GlobalObservationScore.transaction do
      observations = Observation.bigger_date(date)
      reports = ObservationReport.bigger_date(date)

      gos = GlobalObservationScore.find_or_create_by(date: date)

      gos.obs_total = observations.count
      gos.rep_total = reports.count
      gos.rep_country = reports.joins(:observations).group(:country_id).count
      gos.rep_monitor = reports.joins(:observation_report_observers).group(:observer_id).count
      gos.obs_country = observations.group(:country_id).count
      gos.obs_status = observations.group(:validation_status).count
      gos.obs_producer = observations.joins(:operator).group('operators.id').count
      gos.obs_severity = observations.joins(:severity).group('severities.level').count
      gos.obs_category = observations.joins(subcategory: :category).group('categories.id').count
      gos.obs_subcategory = observations.joins(:subcategory).group('subcategories.id').count
      gos.obs_fmu = observations.joins(:fmu).group('fmus.id').count
      gos.obs_forest_type = observations.joins(:fmu).group(:forest_type).count

      gos.save
    end
  end
end

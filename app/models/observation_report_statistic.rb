# frozen_string_literal: true

# == Schema Information
#
# Table name: observation_report_statistics
#
#  id          :integer          not null, primary key
#  date        :date             not null
#  country_id  :integer
#  observer_id :integer
#  total_count :integer          default(0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class ObservationReportStatistic < ApplicationRecord
  include DailyStatistic

  belongs_to :observer, optional: true

  validates :date, uniqueness: {scope: [:country_id, :observer_id]}

  def self.statistic_dimensions
    %w[country_id observer_id]
  end

  def self.generate_for_country_and_day(country_id, day, delete_old = false)
    ObservationReportStatistic.transaction do
      ObservationReportStatistic.where(country_id: country_id, date: day).delete_all if delete_old

      observations_with_active_observers = Observation.joins(:observers).where(observers: {is_active: true}).pluck(:observation_id).uniq
      observations_with_inactive_observers = Observation.joins(:observers).where(observers: {is_active: false}).pluck(:observation_id).uniq
      exclude_observations = observations_with_inactive_observers - observations_with_active_observers
      exclude_observations_sql = exclude_observations.any? ? "AND observations.id NOT IN (#{exclude_observations.join(", ")})" : ""

      reports = ObservationReport.bigger_date(day)
      reports = reports.joins(
        "LEFT OUTER JOIN observations ON observations.observation_report_id = observation_reports.id #{exclude_observations_sql}"
      )
      reports = reports.left_joins(:observers).where(observers: {is_active: [nil, true]})

      reports = reports.where(observations: {country_id: country_id}) if country_id.present?
      reports = reports.distinct

      grouped = reports
        .group(:observer_id)
        .count
        .merge(nil => reports.count) # add total reports count

      grouped.each do |observer_id, count|
        new_stat = ObservationReportStatistic.new(
          date: day,
          country_id: country_id,
          observer_id: observer_id,
          total_count: count
        )
        prev_stat = new_stat.previous_stat

        if prev_stat.present? && prev_stat == new_stat
          Rails.logger.info "Prev score the same, update date of prev score"
          prev_stat.date = day
          prev_stat.save!
        else
          Rails.logger.info "Adding score for country: #{country_id} and #{day}"
          new_stat.save!
        end
      end
    end
  end
end

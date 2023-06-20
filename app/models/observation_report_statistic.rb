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
  belongs_to :country, optional: true
  belongs_to :observer, optional: true

  validates :date, presence: true
  validates :date, uniqueness: {scope: [:country_id, :observer_id]}

  def self.from_date(date)
    date_obj = date.respond_to?(:strftime) ? date : Date.parse(date)
    from_date_sql = where("date > '#{date_obj.to_fs(:db)}'").to_sql
    first_rows_sql = at_date(date_obj).to_sql

    from("(#{from_date_sql} UNION #{first_rows_sql}) as observation_report_statistics")
  end

  def self.at_date(date)
    return none if date.blank?

    date_obj = date.respond_to?(:strftime) ? date : Date.parse(date)

    query = <<~SQL
      (select
        id,
        '#{date_obj.to_fs(:db)}'::date as date,
        country_id,
        observer_id,
        total_count,
        created_at,
        updated_at
       from
       (select row_number() over (partition by country_id, observer_id order by date desc), *
        from observation_report_statistics ors
        where date <= '#{date_obj.to_fs(:db)}'
       ) as stats_by_date
       where stats_by_date.row_number = 1
      ) as observation_report_statistics
    SQL

    ObservationReportStatistic.from(query)
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

  def self.ransackable_scopes(auth_object = nil)
    [:by_country]
  end

  def self.by_country(country_id)
    return all if country_id.nil?
    return where(country_id: nil) if country_id == "null"

    where(country_id: country_id)
  end

  def country_name
    return country.name if country.present?

    "All Countries"
  end

  def previous_stat
    ObservationReportStatistic.where(
      country_id: country_id,
      observer_id: observer_id
    ).where("date < ?", date).order(:date).last
  end

  def ==(other)
    return false unless other.is_a? self.class

    %w[country_id observer_id total_count].reject do |attr|
      send(attr) == other.send(attr)
    end.none?
  end
end

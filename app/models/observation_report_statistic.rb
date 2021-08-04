# frozen_string_literal: true

# == Schema Information
#
# Table name: observation_report_statistics
#
#  id          :integer          not null, primary key
#  date        :date             not null
#  country_id  :integer
#  observer_id :integer
#  total_count :integer          default("0")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class ObservationReportStatistic < ApplicationRecord
  belongs_to :country, optional: true
  belongs_to :observer, optional: true

  validates_presence_of :date
  validates_uniqueness_of :date, scope: [:country_id, :observer_id]

  def self.from_date(date)
    date_obj = date.respond_to?(:strftime) ? date : Date.parse(date)
    from_date_sql = self.where("date > '#{date_obj.to_s(:db)}'").to_sql
    first_rows_sql = self.at_date(date_obj).to_sql

    self.from("(#{from_date_sql} UNION #{first_rows_sql}) as observation_report_statistics")
  end

  def self.at_date(date)
    return none if date.blank?

    date_obj = date.respond_to?(:strftime) ? date : Date.parse(date)

    query = <<~SQL
      (select
        id,
        '#{date_obj.to_s(:db)}'::date as date,
        country_id,
        observer_id,
        total_count,
        created_at,
        updated_at
       from
       (select row_number() over (partition by country_id, observer_id order by date desc), *
        from observation_report_statistics ors
        where date <= '#{date_obj.to_s(:db)}'
       ) as stats_by_date
       where stats_by_date.row_number = 1
      ) as observation_report_statistics
    SQL

    ObservationReportStatistic.from(query)
  end

  def self.ransackable_scopes(auth_object = nil)
    [:by_country]
  end

  def self.by_country(country_id)
    return all if country_id.nil?
    return where(country_id: nil) if country_id == 'null'

    where(country_id: country_id)
  end

  def country_name
    return country.name if country.present?

    'All Countries'
  end

  def previous_stat
    ObservationReportStatistic.where(
      country_id: country_id,
      observer_id: observer_id
    ).where('date < ?', date).order(:date).last
  end

  def ==(obj)
    return false unless obj.is_a? self.class

    %w[country_id observer_id total_count].reject do |attr|
      send(attr) == obj.send(attr)
    end.none?
  end
end

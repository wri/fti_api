# frozen_string_literal: true

# == Schema Information
#
# Table name: observation_statistics
#
#  id                :integer          not null, primary key
#  date              :date             not null
#  country_id        :integer
#  operator_id       :integer
#  subcategory_id    :integer
#  category_id       :integer
#  fmu_id            :integer
#  severity_level    :integer
#  validation_status :integer
#  fmu_forest_type   :integer
#  total_count       :integer          default("0")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# This model wont have any data in DB, sql query will provide data for active admin dashboard
class ObservationStatistic < ApplicationRecord
  belongs_to :country, optional: true
  belongs_to :fmu, optional: true
  belongs_to :category, optional: true
  belongs_to :subcategory, optional: true
  belongs_to :operator, optional: true

  enum validation_status: {
    "Created" => 0, "Ready for QC" => 1, "QC in progress" => 2, "Approved" => 3,
    "Rejected" => 4, "Needs revision" => 5, "Ready for publication" => 6,
    "Published (no comments)" => 7, "Published (not modified)" => 8,
    "Published (modified)" => 9
  }

  validates_presence_of :date

  # just to hack around active admin
  def self.ransackable_scopes(auth_object = nil)
    [:by_country]
  end

  # just to hack around active admin, does not have to filter by country
  def self.by_country(country_id = nil)
    all
  end

  def self.query_dashboard_report(search = {})
    date_from = (search[:date_gteq] || Observation.order(:created_at).first.created_at).to_date.to_s(:db)
    date_to = (search[:date_lteq] || Date.today).to_date.to_s(:db)
    country_id = search[:by_country]
    operator_id = search[:operator_id_eq]
    subcategory_id = search[:subcategory_id_eq]
    category_id = search[:category_id_eq]
    validation_status = search[:validation_status_eq]
    severity_level = search[:severity_level_eq]
    forest_type = search[:fmu_forest_type_eq]

    filters = [
      country_id.nil? || country_id == 'null' ? 'country_id is not null' : "country_id = #{country_id}",
      operator_id.nil? ? nil : "operator_id = #{operator_id}",
      validation_status.nil? ? nil : "validation_status = #{validation_status}",
      forest_type.nil? ? nil : "fmu_forest_type = #{forest_type}",
      severity_level.nil? ? nil : "severity_level = #{severity_level}",
      subcategory_id.nil? ? nil : "subcategory_id = #{subcategory_id}",
      category_id.nil? ? nil : "category_id = #{category_id}"
    ].compact.join(' AND ')
    select = [
      operator_id.nil? ? nil : "#{operator_id} as operator_id",
      validation_status.nil? ? nil : "#{validation_status} as validation_status",
      severity_level.nil? ? nil : "#{severity_level} as severity_level",
      subcategory_id.nil? ? nil : "#{subcategory_id} as subcategory_id",
      category_id.nil? ? nil : "#{category_id} as category_id",
      forest_type.nil? ? nil : "#{forest_type} as fmu_forest_type"
    ].compact.join(',')

    sql = <<~SQL
      with dates as (
        SELECT date_trunc('day', dd)::date as date
        FROM generate_series
            ( '#{date_from}'::timestamp
            , '#{date_to}'::timestamp
            , '1 day'::interval) dd
      ),
      grouped as (
        select
          date,
          country_id,
          count(*) as total_count
        from
        dates
        left join lateral
          (
            select * from (
              select row_number() over (partition by observation_id order by observation_updated_at desc), *
                from observation_histories
              where observation_updated_at <= dates.date
            ) as sq
            where sq.row_number = 1
          ) as observations_by_date on 1=1
        #{filters.present? ? 'where ' + filters : ''}
        group by date, rollup(country_id)
      )
      select
        date,
        country_id,
        #{select.present? ? select + ',' : ''}
        total_count
      from (
        select
          *,
          LAG(total_count,1) OVER (
            partition by country_id
            ORDER BY date
          ) prev_total
          from grouped
      ) as total_c
      where
        (prev_total is null or prev_total != total_count or date = '#{date_to}' or date = '#{date_from}')
        AND (#{country_id.nil? || country_id == 'null' ? '1=1' : 'country_id is not null'})
        AND (#{country_id == 'null' ? 'country_id is null' : '1=1'})
      order by date desc
    SQL

    ActiveRecord::Base.connection.execute(sql).to_a.map do |row|
      ObservationStatistic.new(
        date: row['date'],
        country_id: row['country_id'],
        total_count: row['total_count'],
        operator_id: row['operator_id'],
        category_id: row['category_id'],
        subcategory_id: row['subcategory_id'],
        validation_status: row['validation_status'],
        fmu_forest_type: row['fmu_forest_type'],
        severity_level: row['severity_level']
      )
    end
  end

  def country_name
    return country.name if country.present?

    'All Countries'
  end
end

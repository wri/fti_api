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
#  hidden            :boolean
#  is_active         :boolean
#
class ObservationStatistic < ApplicationRecord
  # this record has table, but there should be no data, as it's used
  # for active admin dashboard, kinda ugly workaround I know
  belongs_to :country, optional: true
  belongs_to :fmu, optional: true
  belongs_to :category, optional: true
  belongs_to :subcategory, optional: true
  belongs_to :operator, optional: true

  enum validation_status: {
    "Created" => 0,
    "Ready for QC" => 1,
    "QC in progress" => 2,
    "Approved" => 3,
    "Rejected" => 4,
    "Needs revision" => 5,
    "Ready for publication" => 6,
    "Published (no comments)" => 7,
    "Published (not modified)" => 8,
    "Published (modified)" => 9,
    "Published (all)" => 789 # extra state for looking for all published
  }
  enum observation_type: { "operator" => 0, "government" => 1 }

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
    observation_type = search[:observation_type_eq]
    is_active = search[:is_active_eq]
    hidden = search[:hidden_eq]

    validation_status_filter = validation_status.to_i === 789 ? '7,8,9' : validation_status

    filters = [
      country_id.nil? || country_id == 'null' ? 'country_id is not null' : "country_id = #{country_id}",
      operator_id.nil? ? nil : "operator_id = #{operator_id}",
      observation_type.nil? ? nil : "observation_type = #{observation_type}",
      validation_status.nil? ? nil : "validation_status IN (#{validation_status_filter})",
      forest_type.nil? ? nil : "fmu_forest_type = #{forest_type}",
      severity_level.nil? ? nil : "severity_level = #{severity_level}",
      subcategory_id.nil? ? nil : "subcategory_id = #{subcategory_id}",
      category_id.nil? ? nil : "category_id = #{category_id}",
      hidden.nil? ? nil : "hidden = #{hidden}",
      is_active.nil? ? nil : "is_active = #{is_active}"
    ].compact.join(' AND ')

    sql = <<~SQL
      with dates as (
        select distinct date from (
          select '#{date_from}'::date
          union
          select distinct date(observation_updated_at + interval '1' day) from observation_histories
          union
          select '#{date_to}'::date
        ) as important_dates
        where date between '#{date_from}' and '#{date_to}'
      ),
      grouped as (
        select
          date,
          country_id,
          validation_status,
          count(*)::integer as total_count
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
        where deleted_at is null #{filters.present? ? 'AND ' + filters : ''}
        group by date, validation_status, rollup(country_id)
      )
      select
        date,
        country_id,
        #{operator_id.presence || 'null'} as operator_id,
        sum(total_count) filter (where validation_status = 0) as created,
        sum(total_count) filter (where validation_status = 1) as ready_for_qc,
        sum(total_count) filter (where validation_status = 2) as qc_in_progress,
        sum(total_count) filter (where validation_status = 3) as approved,
        sum(total_count) filter (where validation_status = 4) as rejected,
        sum(total_count) filter (where validation_status = 5) as needs_revision,
        sum(total_count) filter (where validation_status = 6) as ready_for_publication,
        sum(total_count) filter (where validation_status = 7) as published_no_comments,
        sum(total_count) filter (where validation_status = 8) as published_not_modified,
        sum(total_count) filter (where validation_status = 9) as published_modified,
        sum(total_count) filter (where validation_status IN (7,8, 9)) as published_all,
        sum(total_count) as total_count,
        null as validation_status,
        #{severity_level.presence || 'null'} as severity_level,
        #{subcategory_id.presence || 'null'} as subcategory_id,
        #{category_id.presence || 'null'} as category_id,
        #{observation_type.presence || 'null'} as observation_type,
        #{forest_type.presence || 'null'} as fmu_forest_type,
        #{is_active.nil? ? 'null' : is_active} as is_active,
        #{hidden.nil? ? 'null' : hidden} as hidden
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
      group by date, country_id
      order by date desc, country_id asc nulls first
    SQL

    ObservationStatistic.from(
      "(#{sql}) as observation_statistics"
    ).includes(country: :translations)
  end

  def country_name
    return country.name if country.present?

    'All Countries'
  end

  def readonly?
    true
  end
end
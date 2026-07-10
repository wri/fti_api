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
#  total_count       :integer          default(0)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  hidden            :boolean          default(FALSE), not null
#  is_active         :boolean          default(FALSE), not null
#  observation_type  :integer
#
class ObservationStatistic < ApplicationRecord
  # this record has table, but there should be no data, as it's used
  # for active admin dashboard, kinda ugly workaround I know
  belongs_to :country, optional: true
  belongs_to :fmu, optional: true
  belongs_to :category, optional: true
  belongs_to :subcategory, optional: true
  belongs_to :operator, optional: true

  enum :validation_status, {
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
  enum :observation_type, {"operator" => 0, "government" => 1}
  enum :fmu_forest_type, ForestType::TYPES_WITH_CODE

  validates :date, presence: true

  # report count columns with theirs observation history validation status conditions
  REPORT_COUNT_COLUMNS = {
    created: "= 0",
    ready_for_qc: "IN (1, 10)",
    qc_in_progress: "IN (2, 11)",
    approved: "= 3",
    rejected: "= 4",
    needs_revision: "= 5",
    ready_for_publication: "= 6",
    published_no_comments: "= 7",
    published_not_modified: "= 8",
    published_modified: "= 9",
    published_all: "IN (7, 8, 9)",
    total_count: nil
  }.freeze

  def self.ransackable_scopes(auth_object = nil)
    [:by_country]
  end

  # does not filter, the search object only keeps the filter form state,
  # actual filtering happens in query_dashboard_report
  def self.by_country(country_id = nil)
    all
  end

  def self.query_dashboard_report(search = {})
    date_from = (search[:date_gteq] || Observation.order(:created_at).first.created_at).to_date.to_fs(:db)
    date_to = (search[:date_lteq] || Time.zone.today).to_date.to_fs(:db)
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

    validation_status_filter = (validation_status.to_i === 789) ? [7, 8, 9] : validation_status

    filters = []
    if country_id.nil? || country_id == "null"
      filters.push(["country_id is not null", nil])
    else
      filters.push(["country_id = ?", country_id])
    end
    filters.push(["operator_id = ?", operator_id]) if operator_id.present?
    filters.push(["observation_type = ?", observation_type]) if observation_type.present?
    filters.push(["validation_status IN (?)", validation_status_filter]) if validation_status.present?
    filters.push(["fmu_forest_type = ?", forest_type]) if forest_type.present?
    filters.push(["severity_level = ?", severity_level]) if severity_level.present?
    filters.push(["subcategory_id = ?", subcategory_id]) if subcategory_id.present?
    filters.push(["category_id = ?", category_id]) if category_id.present?
    filters.push(["hidden = ?", hidden]) if hidden.present?
    filters.push(["is_active = ?", is_active]) if is_active.present?
    filters_sql = ActiveRecord::Base.sanitize_sql_for_conditions([filters.map(&:first).join(" AND "), *filters.map(&:last).compact])

    count_sums = REPORT_COUNT_COLUMNS.map { |column, condition|
      status_filter = condition && "filter (where validation_status #{condition}) "
      "coalesce(sum(total_count) #{status_filter}, 0) as #{column}"
    }.join(",\n")
    count_vector = "array[#{REPORT_COUNT_COLUMNS.keys.join(", ")}]"

    sql = <<~SQL
      with dates as (
        select distinct date from (
          select :date_from::date
          union
          select distinct date(observation_updated_at + interval '1' day) from observation_histories
          union
          select :date_to::date
        ) as important_dates
        where date between :date_from and :date_to
      ),
      statuses as (
        select
          *,
          lead(observation_updated_at) over (partition by observation_id order by observation_updated_at) as next_updated_at
        from observation_histories
      ),
      grouped as (
        select
          date,
          country_id,
          validation_status,
          count(*)::integer as total_count
        from dates
        join statuses on
          observation_updated_at <= dates.date
          and (next_updated_at is null or next_updated_at > dates.date)
        where deleted_at is null #{"AND " + filters_sql if filters_sql.present?}
        group by date, validation_status, rollup(country_id)
      ),
      pivoted as (
        select
          date,
          country_id,
          #{count_sums}
        from grouped
        group by date, country_id
      )
      select
        date,
        country_id,
        #{REPORT_COUNT_COLUMNS.keys.join(",\n")},
        #{sql_literal(operator_id)} as operator_id,
        null as validation_status,
        #{sql_literal(severity_level)} as severity_level,
        #{sql_literal(subcategory_id)} as subcategory_id,
        #{sql_literal(category_id)} as category_id,
        #{sql_literal(observation_type)} as observation_type,
        #{sql_literal(forest_type)} as fmu_forest_type,
        #{sql_literal(is_active)} as is_active,
        #{sql_literal(hidden)} as hidden
      from (
        select
          *,
          lag(#{count_vector}) over (
            partition by country_id
            order by date
          ) as prev_counts
        from pivoted
      ) as with_prev
      where
        (prev_counts is null or prev_counts <> #{count_vector} or date in (:date_from, :date_to))
        and (#{(country_id.nil? || country_id == "null") ? "true" : "country_id is not null"})
        and (#{(country_id == "null") ? "country_id is null" : "true"})
      order by date desc, country_id asc nulls first
    SQL

    ObservationStatistic.from(
      ActiveRecord::Base.sanitize_sql([
        "(#{sql}) as observation_statistics",
        {date_from: date_from, date_to: date_to}
      ])
    ).includes(country: :translations)
  end

  def self.sql_literal(value)
    connection.quote(value.presence)
  end
  private_class_method :sql_literal

  def country_name
    return country.name if country.present?

    "All Countries"
  end

  def readonly?
    true
  end
end

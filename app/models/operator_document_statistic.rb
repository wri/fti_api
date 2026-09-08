# frozen_string_literal: true

# == Schema Information
#
# Table name: operator_document_statistics
#
#  id                                  :integer          not null, primary key
#  date                                :date             not null
#  country_id                          :integer
#  required_operator_document_group_id :integer
#  fmu_forest_type                     :integer
#  document_type                       :string
#  valid_count                         :integer          default(0)
#  invalid_count                       :integer          default(0)
#  pending_count                       :integer          default(0)
#  not_provided_count                  :integer          default(0)
#  not_required_count                  :integer          default(0)
#  expired_count                       :integer          default(0)
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#
class OperatorDocumentStatistic < ApplicationRecord
  include DailyStatistic

  belongs_to :required_operator_document_group, optional: true

  enum :fmu_forest_type, ForestType::TYPES_WITH_CODE

  validates :date, uniqueness: {scope: [:country_id, :required_operator_document_group_id, :fmu_forest_type, :document_type]}

  def self.statistic_dimensions
    %w[country_id required_operator_document_group_id fmu_forest_type document_type]
  end

  def self.generate_for_country_and_day(country_id, day, delete_old = false)
    generate_for_day(day, [country_id], delete_old: delete_old)
  end

  # Counts the whole day once, for every country scope at the same time. Postgres does the counting
  # with grouping sets, which also produces the rolled up (nil) buckets, so nothing is counted in ruby.
  def self.generate_for_day(day, country_ids, delete_old: false)
    OperatorDocumentStatistic.transaction do
      counters, observed = day_counters(day)
      previous_stats = latest_stats_before(country_ids, day)

      to_save = []
      to_update = []

      country_ids.each do |country_id|
        OperatorDocumentStatistic.where(country_id: country_id, date: day).delete_all if delete_old

        # a nil country_id is the all countries scope, keyed as :all in the counters
        country_key = country_id.nil? ? :all : country_id
        dims = observed[country_key] || {types: [], forest_types: [], groups: []}

        # a nil dimension is the rollup over that dimension, which the counters key as :all
        (dims[:types] + [nil]).uniq.each do |type|
          (dims[:forest_types] + [nil]).uniq.each do |forest_type|
            (dims[:groups] + [nil]).uniq.each do |group_id|
              count = ->(status) {
                counters[[country_key, group_id.nil? ? :all : group_id,
                  forest_type.nil? ? :all : forest_type, type.nil? ? :all : type, status]] || 0
              }

              new_stat = OperatorDocumentStatistic.new(
                document_type: DOCUMENT_TYPES[type],
                fmu_forest_type: forest_type,
                required_operator_document_group_id: group_id,
                country_id: country_id,
                date: day,
                pending_count: count.call("doc_pending"),
                invalid_count: count.call("doc_invalid"),
                valid_count: count.call("doc_valid"),
                expired_count: count.call("doc_expired"),
                not_required_count: count.call("doc_not_required"),
                not_provided_count: count.call("doc_not_provided")
              )

              # unchanged counters move the previous row's date forward instead of adding a new one
              prev_stat = previous_stats[[country_id, group_id, forest_type, DOCUMENT_TYPES[type]]]
              if prev_stat.present? && prev_stat.same_counters?(new_stat)
                prev_stat.date = day
                prev_stat.updated_at = DateTime.current
                to_update << prev_stat
              else
                to_save << new_stat
              end
            end
          end
        end
      end

      if to_save.count.positive?
        Rails.logger.info "Adding #{to_save.count} scores for #{day}"
        OperatorDocumentStatistic.import! to_save
      end

      if to_update.count.positive?
        Rails.logger.info "Updating #{to_update.count} scores for #{day}"
        OperatorDocumentStatistic.import! to_update, on_duplicate_key_update: {columns: %i[date updated_at]}
      end
    end
  end

  DOCUMENT_TYPES = {
    "OperatorDocumentFmuHistory" => "fmu",
    "OperatorDocumentCountryHistory" => "country"
  }.freeze

  # Every count for the day in one query: grouping sets give each concrete slice and every rolled up
  # combination at once. grouping() tells a rolled up dimension apart from one that is null in the data.
  def self.day_counters(day)
    inner = OperatorDocumentHistory.at_date(day)
      .non_signature
      .left_joins(:fmu)
      .select(
        "operator_document_histories.status as status",
        "operator_document_histories.type as doc_type",
        "fmus.forest_type as forest_type",
        "required_operator_documents.required_operator_document_group_id as group_id",
        "required_operator_documents.country_id as country_id"
      ).to_sql

    sql = <<~SQL
      select country_id, group_id, forest_type, doc_type, status, count(*) as n,
             grouping(country_id) as g_country, grouping(group_id) as g_group,
             grouping(forest_type) as g_forest, grouping(doc_type) as g_doc
      from (#{inner}) as documents
      group by cube (country_id, group_id, forest_type, doc_type), status
    SQL

    counters = {}
    observed = Hash.new { |hash, key| hash[key] = {types: [], forest_types: [], groups: []} }

    connection.select_all(sql).each do |row|
      country = (row["g_country"] == 1) ? :all : row["country_id"]
      group = (row["g_group"] == 1) ? :all : row["group_id"]
      forest = (row["g_forest"] == 1) ? :all : forest_type_name(row["forest_type"])
      doc_type = (row["g_doc"] == 1) ? :all : row["doc_type"]
      # select_all skips the AR enum casting, so integers have to be mapped back to names
      status = OperatorDocumentHistory.statuses.key(row["status"]) || row["status"]

      counters[[country, group, forest, doc_type, status]] = row["n"]

      # the nil entry of every dimension is the rolled up bucket, so only concrete values are collected
      dims = observed[country]
      dims[:types] << doc_type unless doc_type == :all || doc_type.nil? || dims[:types].include?(doc_type)
      dims[:forest_types] << forest unless forest == :all || forest.nil? || dims[:forest_types].include?(forest)
      dims[:groups] << group unless group == :all || group.nil? || dims[:groups].include?(group)
    end

    [counters, observed]
  end
  private_class_method :day_counters

  def self.forest_type_name(value)
    return value if value.nil? || value.is_a?(String)

    Fmu.forest_types.key(value)
  end
  private_class_method :forest_type_name

  # latest stat of every series before the day, for all the given countries in one query
  def self.latest_stats_before(country_ids, day)
    dimensions = statistic_dimensions.join(", ")

    # distinct on requires the order to start with the same dimensions, date desc then picks the latest
    where(country_id: country_ids)
      .where("date < ?", day)
      .select(Arel.sql("distinct on (#{dimensions}) #{table_name}.*"))
      .order(Arel.sql("#{dimensions}, date desc, id desc"))
      .index_by { |stat|
        [stat.country_id, stat.required_operator_document_group_id, stat.fmu_forest_type, stat.document_type]
      }
  end
  private_class_method :latest_stats_before

  def self.ransackable_scopes(auth_object = nil)
    [:by_country, :by_required_operator_document_group]
  end

  def self.by_required_operator_document_group(*group_id)
    where(required_operator_document_group_id: group_id.map { |c| (c === "null") ? nil : c })
  end

  def valid_and_expired_count
    valid_count + expired_count
  end
end

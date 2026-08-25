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
    OperatorDocumentStatistic.transaction do
      OperatorDocumentStatistic.where(country_id: country_id, date: day).delete_all if delete_old

      docs = OperatorDocumentHistory.at_date(day)
        .non_signature
        .left_joins(:fmu)
      docs = docs.where(required_operator_documents: {country_id: country_id}) if country_id.present?

      # plucked rather than instantiated, forest_type and required_operator_document_group_id come from
      # the joins, so reading them off a record goes through method_missing and dominates the runtime
      rows = docs.pluck(
        :status,
        "operator_document_histories.type",
        "fmus.forest_type",
        "required_operator_documents.required_operator_document_group_id"
      )

      types = (rows.map { |row| row[1] } + [nil]).uniq
      forest_types = (rows.map { |row| row[2] } + [nil]).uniq
      groups = (rows.map { |row| row[3] } + [nil]).uniq

      # a document counts towards its own value and towards the nil (all) bucket of every dimension,
      # counted in one pass instead of scanning every document once per combination
      counters = Hash.new(0)
      rows.each do |status, type, forest_type, group_id|
        [type, nil].uniq.each do |a_type|
          [forest_type, nil].uniq.each do |a_forest_type|
            [group_id, nil].uniq.each do |a_group_id|
              counters[[a_type, a_forest_type, a_group_id, status]] += 1
            end
          end
        end
      end

      previous_stats = latest_stats_before(country_id, day)

      to_save = []
      to_update = []

      types.each do |type|
        forest_types.each do |forest_type|
          groups.each do |group_id|
            new_stat = OperatorDocumentStatistic.new(
              document_type: case type
                             when "OperatorDocumentFmuHistory"
                               "fmu"
                             when "OperatorDocumentCountryHistory"
                               "country"
                             end,
              fmu_forest_type: forest_type,
              required_operator_document_group_id: group_id,
              country_id: country_id,
              date: day,
              pending_count: counters[[type, forest_type, group_id, "doc_pending"]],
              invalid_count: counters[[type, forest_type, group_id, "doc_invalid"]],
              valid_count: counters[[type, forest_type, group_id, "doc_valid"]],
              expired_count: counters[[type, forest_type, group_id, "doc_expired"]],
              not_required_count: counters[[type, forest_type, group_id, "doc_not_required"]],
              not_provided_count: counters[[type, forest_type, group_id, "doc_not_provided"]]
            )

            prev_stat = previous_stats[new_stat.attributes.slice(*statistic_dimensions)]
            if prev_stat.present? && prev_stat.same_counters?(new_stat)
              Rails.logger.info "Prev score the same, update date of prev score"
              prev_stat.date = day
              prev_stat.updated_at = DateTime.current
              to_update << prev_stat
            else
              Rails.logger.info "Adding score for country: #{country_id} and #{day}"
              to_save << new_stat
            end
          end
        end
      end

      if to_save.count.positive?
        Rails.logger.info "Adding score for country: #{country_id} and #{day}, count: #{to_save.count}"
        OperatorDocumentStatistic.import! to_save
      end

      if to_update.count.positive?
        Rails.logger.info "Updating scores for country: #{country_id} and #{day}, count: #{to_update.count}"
        OperatorDocumentStatistic.import! to_update, on_duplicate_key_update: {columns: %i[date updated_at]}
      end
    end
  end

  # latest stat of every series before the day, in one query instead of one per combination
  def self.latest_stats_before(country_id, day)
    dimensions = statistic_dimensions.join(", ")

    where(country_id: country_id)
      .where("date < ?", day)
      .select(Arel.sql("distinct on (#{dimensions}) #{table_name}.*"))
      .order(Arel.sql("#{dimensions}, date desc, id desc"))
      .index_by { |stat| stat.attributes.slice(*statistic_dimensions) }
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

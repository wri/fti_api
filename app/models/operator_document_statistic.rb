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
        .select(:status, "operator_document_histories.type", "fmus.forest_type", "required_operator_documents.required_operator_document_group_id")
      docs = docs.where(required_operator_documents: {country_id: country_id}) if country_id.present?

      types = (docs.pluck(:type) + [nil]).uniq
      forest_types = (docs.pluck(:forest_type) + [nil]).uniq
      groups = (docs.pluck(:required_operator_document_group_id) + [nil]).uniq

      to_save = []
      to_update = []

      types.each do |type|
        forest_types.each do |forest_type|
          groups.each do |group_id|
            filtered = docs.select do |d|
              (forest_type.nil? || d.forest_type == forest_type) &&
                (type.nil? || d.type == type) &&
                (group_id.nil? || d.required_operator_document_group_id == group_id)
            end.group_by(&:status)

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
              pending_count: filtered["doc_pending"]&.count || 0,
              invalid_count: filtered["doc_invalid"]&.count || 0,
              valid_count: filtered["doc_valid"]&.count || 0,
              expired_count: filtered["doc_expired"]&.count || 0,
              not_required_count: filtered["doc_not_required"]&.count || 0,
              not_provided_count: filtered["doc_not_provided"]&.count || 0
            )

            prev_stat = new_stat.previous_stat
            if prev_stat.present? && prev_stat == new_stat
              Rails.logger.info "Prev score the same, update date of prev score"
              prev_stat.date = day
              prev_stat.updated_at = DateTime.current
              to_update << prev_stat
            elsif prev_stat.blank? || prev_stat != new_stat
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

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
  belongs_to :country, optional: true
  belongs_to :required_operator_document_group, optional: true

  enum fmu_forest_type: ForestType::TYPES_WITH_CODE

  validates_presence_of :date
  validates_uniqueness_of :date, scope: [:country_id, :required_operator_document_group_id, :fmu_forest_type, :document_type]

  def self.from_date(date)
    date_obj = date.respond_to?(:strftime) ? date : Date.parse(date)
    from_date_sql = where("date > '#{date_obj.to_fs(:db)}'").to_sql
    first_rows_sql = at_date(date_obj).to_sql

    from("(#{from_date_sql} UNION #{first_rows_sql}) as operator_document_statistics")
  end

  def self.at_date(date)
    return none if date.blank?

    date_obj = date.respond_to?(:strftime) ? date : Date.parse(date)

    query = <<~SQL
      (select
        id,
        '#{date_obj.to_fs(:db)}'::date as date,
        country_id,
        required_operator_document_group_id,
        fmu_forest_type,
        document_type,
        valid_count,
        invalid_count,
        pending_count,
        not_provided_count,
        not_required_count,
        expired_count,
        created_at,
        updated_at
       from
       (select row_number() over (partition by country_id, required_operator_document_group_id, fmu_forest_type, document_type order by date desc), *
        from operator_document_statistics ods
        where date <= '#{date_obj.to_fs(:db)}'
       ) as stats_by_date
       where stats_by_date.row_number = 1
      ) as operator_document_statistics
    SQL

    OperatorDocumentStatistic.from(query)
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

  def self.by_country(country_id)
    return all if country_id.nil?
    return where(country_id: nil) if country_id == "null"

    where(country_id: country_id)
  end

  def self.by_required_operator_document_group(*group_id)
    where(required_operator_document_group_id: group_id.map { |c| (c === "null") ? nil : c })
  end

  def previous_stat
    OperatorDocumentStatistic.where(
      country_id: country_id,
      fmu_forest_type: fmu_forest_type,
      required_operator_document_group_id: required_operator_document_group_id,
      document_type: document_type
    ).where("date < ?", date).order(:date).last
  end

  def valid_and_expired_count
    valid_count + expired_count
  end

  def country_name
    return country.name if country.present?

    "All Countries"
  end

  def ==(other)
    return false unless other.is_a? self.class

    %w[country_id required_operator_document_group_id fmu_forest_type document_type pending_count expired_count invalid_count valid_count not_provided_count not_required_count].reject do |attr|
      send(attr) == other.send(attr)
    end.none?
  end
end

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
#  valid_count                         :integer          default("0")
#  invalid_count                       :integer          default("0")
#  pending_count                       :integer          default("0")
#  not_provided_count                  :integer          default("0")
#  not_required_count                  :integer          default("0")
#  expired_count                       :integer          default("0")
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#
class OperatorDocumentStatistic < ApplicationRecord
  belongs_to :country, optional: true
  belongs_to :required_operator_document_group, optional: true

  validates_presence_of :date
  validates_uniqueness_of :date, scope: [:country_id, :required_operator_document_group_id, :fmu_forest_type, :document_type]

  def self.from_date(date)
    date_obj = date.respond_to?(:strftime) ? date : Date.parse(date)
    from_date_sql = self.where("date > '#{date_obj.to_s(:db)}'").to_sql
    first_rows_sql = self.at_date(date_obj).to_sql

    self.from("(#{from_date_sql} UNION #{first_rows_sql}) as operator_document_statistics")
  end

  def self.at_date(date)
    return none if date.blank?

    date_obj = date.respond_to?(:strftime) ? date : Date.parse(date)

    query = <<~SQL
      (select
        id,
        '#{date_obj.to_s(:db)}'::date as date,
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
        where date <= '#{date_obj.to_s(:db)}'
       ) as stats_by_date
       where stats_by_date.row_number = 1
      ) as operator_document_statistics
    SQL

    OperatorDocumentStatistic.from(query)
  end

  def self.ransackable_scopes(auth_object = nil)
    [:by_country, :by_required_operator_document_group]
  end

  # def self.by_country(*country_id)
  #   # return all if country_id.nil?
  #   # return where(country_id: nil) if country_id == 'null'
  #   where(country_id: country_id.map { |c| c === 'null' ? nil : c })
  # end

  def self.by_country(country_id)
    return all if country_id.nil?
    return where(country_id: nil) if country_id == 'null'

    where(country_id: country_id)
  end

  def self.by_required_operator_document_group(*group_id)
    where(required_operator_document_group_id: group_id.map { |c| c === 'null' ? nil : c })
  end

  def previous_stat
    OperatorDocumentStatistic.where(
      country_id: country_id,
      fmu_forest_type: fmu_forest_type,
      required_operator_document_group_id: required_operator_document_group_id,
      document_type: document_type
    ).where('date < ?', date).order(:date).last
  end

  def valid_and_expired_count
    valid_count + expired_count
  end

  def country_name
    return country.name if country.present?

    'All Countries'
  end

  def ==(obj)
    return false unless obj.is_a? self.class

    %w[country_id required_operator_document_group_id fmu_forest_type document_type pending_count expired_count invalid_count valid_count not_provided_count not_required_count].reject do |attr|
      send(attr) == obj.send(attr)
    end.none?
  end
end

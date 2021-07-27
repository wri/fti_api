# frozen_string_literal: true

# == Schema Information
#
# Table name: global_scores
#
#  id               :integer          not null, primary key
#  date             :datetime         not null
#  total_required   :integer
#  general_status   :jsonb
#  country_status   :jsonb
#  fmu_status       :jsonb
#  doc_group_status :jsonb
#  fmu_type_status  :jsonb
#  country_id       :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class NewGlobalScore < ApplicationRecord
  belongs_to :country, optional: true
  belongs_to :required_operator_document_group, optional: true

  validates_presence_of :date
  # validates_uniqueness_of :date, scope: :country_id

  def self.ransackable_scopes(auth_object = nil)
    [:by_country]
  end

  def self.by_country(country_id = nil)
    return all if country_id.nil?
    return where(country_id: nil) if country_id == 'null'

    where(country_id: country_id)
  end

  def self.by_country(*countries)
    # return all if country_id.nil?
    # return where(country_id: nil) if country_id == 'null'

    where(country_id: countries)
  end

  scope :total, -> { where(document_type: nil, fmu_forest_type: nil, required_operator_document_group_id: nil, country_id: nil) }

  def previous_score
    NewGlobalScore.where(country_id: country_id).where('date < ?', date).order(:date).last
  end

  def country_name
    return country.name if country.present?

    'All Countries'
  end

  def ==(obj)
    return false unless obj.is_a? self.class

    %w[country_id doc_pending doc_expired doc_invalid doc_valid doc_not_provided doc_not_required].reject do |attr|
      send(attr) == obj.send(attr)
    end.none?
  end
end

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
class GlobalScore < ApplicationRecord
  belongs_to :country, optional: true
  validates_presence_of :date
  validates_uniqueness_of :date, scope: :country_id

  attr_accessor :active_filters

  # below scopes are to hack around ransack
  # maybe better instead to create custom index in active admin
  def self.ransackable_scopes(auth_object = nil)
    [:by_country, :by_document_group, :by_document_type, :by_forest_type]
  end
  scope :by_document_group, ->(_param = nil) { all }
  scope :by_document_type, ->(_param = nil) { all }
  scope :by_forest_type, ->(_param = nil) { all }
  def self.by_country(country_id = nil)
    return all if country_id.nil?
    return where(country_id: nil) if country_id == 'null'

    where(country_id: country_id)
  end

  def previous_score
    GlobalScore.where(country_id: country_id).where('date < ?', date).order(:date).last
  end

  def country_name
    return country.name if country.present?

    'All Countries'
  end

  def pending
    count_by_status 'doc_pending'
  end

  def expired
    count_by_status 'doc_expired'
  end

  def invalid
    count_by_status 'doc_invalid'
  end

  def valid
    count_by_status 'doc_valid'
  end

  def not_provided
    count_by_status 'doc_not_provided'
  end

  def not_required
    count_by_status 'doc_not_required'
  end

  def count_by_status(status)
    docs = general_status.select do |d|
      d['s'] == OperatorDocument.statuses[status] &&
        (active_filters[:by_document_type].blank? || d['t'] == active_filters[:by_document_type].downcase) &&
        (active_filters[:by_document_group].blank? || d['g'] == active_filters[:by_document_group].to_i) &&
        (active_filters[:by_forest_type].blank? || d['f'] == active_filters[:by_forest_type].to_i)
    end
    docs.count
  end

  def active_filters
    @active_filters || {}
  end

  def ==(obj)
    return false unless obj.is_a? self.class

    %w[country_id pending expired invalid valid not_provided not_required].reject do |attr|
      send(attr) == obj.send(attr)
    end.none?
  end

  # Calculates the score for a given day
  # @param [Country] country The country for which to calculate the global score (if nil, will calculate all)
  def self.calculate(country = nil)
    (10.days.ago.to_date..Date.today.to_date).each do |day|
      GlobalScore.transaction do
        gs = GlobalScore.find_or_create_by(country: country, date: day)
        all = country.present? ? OperatorDocument.by_country(country&.id) : OperatorDocument.all
        gs.general_status = all
          .includes(:fmu, :required_operator_document)
          .map do |d|
            {
              t: d.type === 'OperatorDocumentCountry' ? 'country' : 'fmu',
              g: d.required_operator_document.required_operator_document_group_id,
              f: Fmu.forest_types[d.fmu&.forest_type],
              s: OperatorDocument.statuses[d.status]
            }
          end
        gs.save!
      end
    end
  end
end

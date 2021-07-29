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

  def valid_count
    @valid_count ||= count_by_status 'doc_valid'
  end

  def expired_count
    @expired_count ||= count_by_status 'doc_expired'
  end

  def valid_and_expired_count
    valid_count + expired_count
  end

  def pending_count
    @pending_count ||= count_by_status 'doc_pending'
  end

  def invalid_count
    @invalid_count ||= count_by_status 'doc_invalid'
  end

  def not_provided_count
    @not_provided_count ||= count_by_status 'doc_not_provided'
  end

  def not_required_count
    @not_required_count ||= count_by_status 'doc_not_required'
  end

  def count_by_status(status)
    document_type = active_filters[:by_document_type]&.downcase
    document_group = active_filters[:by_document_group]&.to_i
    forest_type = active_filters[:by_forest_type]&.to_i

    docs = (general_status[status] || []).select do |d|
      (document_type.blank? || d['t'] == document_type) &&
        (document_group.blank? || d['g'] == document_group) &&
        (forest_type.blank? || d['f'] == forest_type)
    end

    docs.count
  end

  def active_filters
    @active_filters || {}
  end

  def ==(obj)
    return false unless obj.is_a? self.class

    %w[country_id general_status].reject do |attr|
      send(attr) == obj.send(attr)
    end.none?
  end

  # Calculates the score for a given day
  # @param [Country_id] country The country for which to calculate the global score (if nil, will calculate all)
  # @param [day] day for which to calculate
  def self.calculate(country_id = nil, day = Date.yesterday.to_date)
    Rails.logger.info "Checking score for country: #{country_id} and #{day}"
    gs = GlobalScore.find_or_initialize_by(country_id: country_id, date: day)
    docs = OperatorDocumentHistory.at_date(day)
      .non_signature
      .left_joins(:fmu)
      .select(:status, 'operator_document_histories.type', 'fmus.forest_type', 'required_operator_documents.required_operator_document_group_id')
    docs = docs.where(required_operator_documents: { country_id: country_id }) if country_id.present?

    gs.general_status = docs.group_by(&:status).map do |status, docs|
      {
        status => docs.map do |d|
          {
            t: d.type === 'OperatorDocumentCountryHistory' ? 'country' : 'fmu',
            g: d.required_operator_document_group_id,
            f: d.forest_type
          }
        end
      }
    end.reduce(&:merge)

    prev_score = gs.previous_score
    if prev_score.present? && prev_score == gs && prev_score.previous_score.present?
      Rails.logger.info "Prev score the same, update date of prev score"
      prev_score.update(date: day)
    else
      Rails.logger.info "Adding score for country: #{country_id} and #{day}"
      gs.save!
    end
  end
end

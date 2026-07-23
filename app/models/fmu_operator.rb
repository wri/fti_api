# frozen_string_literal: true

# == Schema Information
#
# Table name: fmu_operators
#
#  id          :integer          not null, primary key
#  fmu_id      :integer          not null
#  operator_id :integer          not null
#  current     :boolean          default(FALSE), not null
#  start_date  :date
#  end_date    :date
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#

class FmuOperator < ApplicationRecord
  has_paper_trail
  acts_as_paranoid

  include DateHelper

  belongs_to :fmu, optional: true
  belongs_to :operator, optional: false

  before_validation :set_current_start_date
  validates :start_date, presence: true
  validate :start_date_is_earlier
  validate :one_active_per_fmu
  validate :non_colliding_dates

  after_save :update_documents_list
  after_save :update_fmu_geojson

  # Sets the start date as today, if none is provided
  def set_current_start_date
    self.start_date = Time.zone.today if start_date.blank?
  end

  # Validates if the start date is earlier than the end date
  def start_date_is_earlier
    return if end_date.blank?

    unless start_date < end_date
      errors.add(:start_date, "Start date must be earlier than end date")
    end
  end

  # Ensures only one operator is active per fmu
  def one_active_per_fmu
    return true if fmu.blank? || !current || fmu.fmu_operators.where(current: true).where.not(id: id).none?

    errors.add(:current, "There can only be one active operator at a time")
  end

  # Makes sure the dates don't collide
  def non_colliding_dates
    return true if fmu.blank? || !fmu.persisted?

    dates = FmuOperator.where(fmu_id: fmu_id).where.not(id: id).pluck(:start_date, :end_date)
    dates << [start_date, end_date]

    (0...(dates.count - 1)).each do |i|
      ((i + 1)...(dates.count)).each do |j|
        errors.add(:end_date, "Cannot have two operators without end date") and return false if dates[i][1].nil? && dates[j][1].nil?

        if intersects?(dates[i], dates[j])
          errors.add(:start_date, "Colliding dates") and return false
        end
      end
    end

    true
  end

  # Calculates and sets all the current operator_fmus on a given day
  def self.calculate_current
    # Checks which one should be active
    today = Time.zone.today
    to_deactivate = FmuOperator.where("current = 'TRUE' AND end_date < :today::date", {today: today})
    to_activate = FmuOperator
      .where("current = 'FALSE' AND start_date <= :today::date AND (end_date IS NULL OR end_date >= :today::date)", {today: today})

    # Updates the operator documents
    to_deactivate.find_each { |x|
      x.current = false
      x.save!(validate: false)
    }
    to_activate.find_each do |x|
      x.current = true
      x.save!(validate: false)
    end
  end

  # Updates the list of documents for this FMU
  def update_documents_list
    return if fmu_id.blank?

    current_operator = fmu.reload.operator

    OperatorDocumentFmu.transaction do
      # FMUs in non-active countries use the generic required documents (country_id is null)
      documents_country_id = Country.active.exists?(id: fmu.country_id) ? fmu.country_id : nil
      required_documents = RequiredOperatorDocumentFmu
        .where(country_id: documents_country_id)
        .for_forest_type(fmu.forest_type)

      to_destroy = OperatorDocumentFmu.includes(:operator).where(fmu_id: fmu_id)
      if current_operator.present?
        to_destroy = to_destroy
          .where.not(operator_id: current_operator.id)
          .or(to_destroy.where.not(required_operator_document_id: required_documents.select(:id)))
      end

      operators_to_recalculate = to_destroy.map(&:operator).uniq
      to_destroy.each do |document|
        document.skip_score_recalculation = true # just do it once for each operator at the end
        document.destroy
      end
      Rails.logger.info "Destroyed #{to_destroy.size} documents for FMU #{fmu_id} that don't belong to #{current_operator&.id} or no longer match the forest type"

      if current_operator.present? && current_operator.fa_id.present?
        created_count = 0
        required_documents.find_each do |required_document|
          OperatorDocumentFmu.where(
            required_operator_document_id: required_document.id,
            operator_id: current_operator.id,
            fmu_id: fmu_id
          ).first_or_create do |document|
            document.skip_score_recalculation = true
            document.status = OperatorDocument.statuses[:doc_not_provided]
            created_count += 1
          end
        end
        operators_to_recalculate << current_operator if created_count > 0
        Rails.logger.info "Created #{created_count} documents for operator #{current_operator.id} and FMU #{fmu_id}"
      end

      operators_to_recalculate.uniq.each do |operator|
        ScoreOperatorDocument.recalculate!(operator)
        Rails.logger.info "Recalculated scores for operator #{operator.id}"
      end
    end
  end

  private

  def update_fmu_geojson
    return unless current
    return if end_date && (end_date < Time.zone.today)
    return if start_date > Time.zone.today

    fmu.reload.save
  end
end

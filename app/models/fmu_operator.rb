# frozen_string_literal: true

# == Schema Information
#
# Table name: fmu_operators
#
#  id          :integer          not null, primary key
#  fmu_id      :integer          not null
#  operator_id :integer          not null
#  current     :boolean          not null
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
    to_deactivate = FmuOperator.where("current = 'TRUE' AND end_date < '#{Time.zone.today}'::date")
    to_activate = FmuOperator
      .where("current = 'FALSE' AND start_date <= '#{Time.zone.today}'::date AND (end_date IS NULL OR end_date >= '#{Time.zone.today}'::date)")

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

  # Updates the list of documents for this FMU, TODO: move it to some service object
  def update_documents_list
    current_operator = self&.fmu&.reload&.operator

    OperatorDocumentFmu.transaction do
      to_destroy = OperatorDocumentFmu.includes(:operator).where(fmu_id: fmu_id)
      to_destroy = to_destroy.where.not(operator_id: current_operator.id) if current_operator.present?
      destroyed_count = to_destroy.count
      to_destroy.each do |doc|
        doc.skip_score_recalculation = true # just do it once for each operator at the end
        doc.destroy
      end
      to_destroy.map(&:operator).uniq.each { |operator| ScoreOperatorDocument.recalculate!(operator) }

      Rails.logger.info "Destroyed #{destroyed_count} documents for FMU #{fmu_id} that don't belong to #{current_operator&.id}"

      # commit current transaction
      next if current_operator.blank? || current_operator.fa_id.blank?

      # Only the RODF for this fmu's forest_type should be created
      rodf_query = "country_id = #{fmu.country_id} "
      rodf_query += " AND '#{Fmu.forest_types[fmu.forest_type]}' = ANY (forest_types)" if fmu.forest_type != "fmu"

      RequiredOperatorDocumentFmu.where(rodf_query).find_each do |rodf|
        OperatorDocumentFmu.where(required_operator_document_id: rodf.id,
          operator_id: current_operator.id,
          fmu_id: fmu_id).first_or_create do |odf|
          odf.skip_score_recalculation = true # just do it once at the end
          odf.update!(status: OperatorDocument.statuses[:doc_not_provided]) unless odf.persisted?
        end
      end
      ScoreOperatorDocument.recalculate!(current_operator)
      Rails.logger.info "Create the documents for operator #{current_operator.id} and FMU #{fmu_id}"
    end
  end

  private

  def update_fmu_geojson
    return unless current
    return if end_date && (end_date < Time.zone.today)
    return if start_date > Time.zone.today

    fmu.save
  end
end

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
#

class FmuOperator < ApplicationRecord
  include DateHelper

  belongs_to :fmu,        required: true
  belongs_to :operator,   required: true

  before_validation     :set_current_start_date
  validates_presence_of :start_date
  validate :start_date_is_earlier
  validate :one_active_per_fmu
  validate :non_colliding_dates

  after_save :update_documents_list


  # Sets the start date as today, if none is provided
  def set_current_start_date
    self.start_date = Date.today if self.start_date.blank?
  end

  # Validates if the start date is earlier than the end date
  def start_date_is_earlier
    return if end_date.blank?
    unless start_date < end_date
      errors.add(:start_date, 'Start date must be earlier than end date')
    end
  end

  # Ensures only one operator is active per fmu
  def one_active_per_fmu
    return false if fmu.blank?
    count = persisted? ? 1 : 0
    unless fmu.fmu_operators.where(current: true).count <= count
      errors.add(:current, 'There can only be one active operator at a time')
    end
  end

  # Makes sure the dates don't collide
  def non_colliding_dates
    dates = FmuOperator.where(fmu_id: self.fmu_id).where.not(fmu_id: self.fmu_id).pluck(:start_date, :end_date)
    dates << [self.start_date, self.end_date]

    for i in 0...(dates.count - 1)
      for j in (i + 1)...(dates.count)
        errors.add(:end_date, 'Cannot have two operators without end date') and return if dates[i][1].nil? && dates[j][1].nil?

        if intersects?(dates[i], dates[j])
          errors.add(:start_date, 'Colliding dates') and return
        end
      end
    end

    true
  end

  # Calculates and sets all the current operator_fmus on a given day
  def self.calculate_current
    # Checks which one should be active
    to_deactivate = FmuOperator.where("current = 'TRUE' AND end_date < '#{Date.today}'::date")
    to_activate   = FmuOperator.
        where("current = 'FALSE' AND start_date <= '#{Date.today}'::date AND (end_date IS NULL OR end_date >= '#{Date.today}'::date)")

    # Updates the operator documents
    to_deactivate.find_each{ |x| x.current = false; x.save!(validate: false) }
    to_activate.find_each do |x|
      x.current = true
      x.save!(validate: false)

      query = "
update fmus
set geojson = jsonb_set(geojson, '{properties}',
    (SELECT JSONB_BUILD_OBJECT('properties', geojson->'properties' || '{\"company_na\": \"#{x.operator&.name}\", \"operator_id\": #{x.operator_id}}'::JSONB)
    FROM fmus
    where fmus.id = #{x.fmu_id}), true)
WHERE id = #{x.fmu_id};"

      ActiveRecord::Base.connection.execute(query)
    end
  end

  private

  # Updates the list of documents for this FMU
  def update_documents_list
    current_operator = self.fmu.operator.id rescue nil
    return unless self.operator.fa_id.present?

    OperatorDocumentFmu.transaction do
      destroyed_count = OperatorDocumentFmu.where(fmu_id: fmu_id).where.not(operator_id: current_operator).delete_all
      Rails.logger.info "Destroyed #{destroyed_count} documents for FMU #{fmu_id} that don't belong to #{current_operator}"

      return unless current_operator
      RequiredOperatorDocumentFmu.where(country_id: fmu.country_id).each do |rodf|
        OperatorDocumentFmu.where(required_operator_document_id: rodf.id,
                                  operator_id: current_operator,
                                  fmu_id: fmu_id).first_or_create do |odf|
          odf.update_attributes!(status: OperatorDocument.statuses[:doc_not_provided], current: true) unless odf.persisted?
        end
      end
      Rails.logger.info "Create the documents for operator #{current_operator} and FMU #{fmu_id}"
    end
  end
end

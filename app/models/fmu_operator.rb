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
#

class FmuOperator < ApplicationRecord
  include DateHelper

  belongs_to :fmu,        required: true
  belongs_to :operator,   required: true
  validates_presence_of :start_date
  validate :start_date_is_earlier
  validate :one_active_per_fmu
  validate :non_colliding_dates


  # Validates if the start date is earlier than the end date
  def start_date_is_earlier
    return if end_date.blank?
    unless start_date < end_date
      errors.add(:start_date, 'Start date must be earlier than end date')
    end
  end

  # Insures only one operator is active per fmu
  def one_active_per_fmu
    return false unless fmu.present?
    unless fmu.fmu_operators.where(current: true).count <= 1
      errors.add(:current, 'There can only be one active operator at a time')
    end
  end

  # Makes sure the dates don't collide
  def non_colliding_dates
    dates = FmuOperator.where(fmu_id: self.fmu_id).pluck(:start_date, :end_date)
    dates << [self.start_date, self.end_date]

    for i in 0...(dates.count - 1)
      for j in (i + 1)...(dates.count)
        errors.add(:end_date, 'Cannot have two operators without end date') and return if dates[i][1].nil? && dates[j][1].nil?

        if intersects?(dates[i], dates[j])
          errors.add(:start_date, 'Colliding dates') and return
        end
      end
    end

    return true
  end

  # Calculates and sets all the active operator_fmus on a given day
  def self.calculate_active
    # Checks which one should be active

    # Updates the operator documents
  end


end

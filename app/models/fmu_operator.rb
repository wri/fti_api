class FmuOperator < ApplicationRecord

  belongs_to :fmu,        required: true
  belongs_to :operator,   required: true
  validate :one_active_per_fmu


  # Insures only one operator is active per fmu
  def one_active_per_fmu
    return false unless fmu.present?
    fmu.fmu_operators.where(current: true).count <= 1
  end

  # Calculates and sets all the active operator_fmus on a given day
  def self.calculate_active

  end


end
class AddDecisionToQualityControl < ActiveRecord::Migration[7.2]
  class QualityControl < ApplicationRecord
  end

  def up
    add_column :quality_controls, :decision, :string

    QualityControl.find_each do |qc|
      qc.update!(decision: qc.metadata["decision"])
    end

    change_column_null :quality_controls, :decision, false
  end

  def down
    QualityControl.find_each do |qc|
      next if qc.metadata.present? && qc.metadata["decision"].present?

      qc.metadata ||= {}
      qc.metadata["decision"] = qc.decision
      qc.save!
    end

    remove_column :quality_controls, :decision
  end
end

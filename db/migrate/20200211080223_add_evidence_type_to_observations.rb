class AddEvidenceTypeToObservations < ActiveRecord::Migration[5.0]
  def change
    add_column :observations, :evidence_type, :integer
  end
end

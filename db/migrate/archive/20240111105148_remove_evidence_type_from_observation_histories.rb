class RemoveEvidenceTypeFromObservationHistories < ActiveRecord::Migration[7.0]
  def change
    remove_column :observation_histories, :evidence_type, :integer
  end
end

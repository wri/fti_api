class AddDeletedAtToObservationDocumentsObservation < ActiveRecord::Migration[7.0]
  def change
    add_column :observation_documents_observations, :deleted_at, :datetime
    add_index :observation_documents_observations, :deleted_at
  end
end

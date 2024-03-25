class RemoveUserFromObservationDocuments < ActiveRecord::Migration[7.0]
  def change
    remove_reference :observation_documents, :user, index: true, foreign_key: true
  end
end

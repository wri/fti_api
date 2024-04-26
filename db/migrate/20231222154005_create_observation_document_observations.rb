class CreateObservationDocumentObservations < ActiveRecord::Migration[7.0]
  def up
    create_table :observation_documents_observations do |t|
      t.belongs_to :observation_document, foreign_key: {on_delete: :cascade}, index: {name: "observation_documents_observations_doc_index"}, null: false
      t.belongs_to :observation, foreign_key: {on_delete: :cascade}, index: {name: "observation_documents_observations_obs_index"}, null: false
      t.index [:observation_document_id, :observation_id], unique: true, name: "observation_documents_observations_double_index"
      t.timestamps
    end

    query = <<-SQL
      INSERT INTO observation_documents_observations (observation_document_id, observation_id, created_at, updated_at)
      SELECT
        od.id, o.id, NOW(), NOW()
      FROM
        observation_documents od JOIN observations o ON od.observation_id = o.id
    SQL
    execute(query)

    remove_reference :observation_documents, :observation
  end

  def down
    add_reference :observation_documents, :observation, foreign_key: true, index: true

    query = <<-SQL
      UPDATE observation_documents SET observation_id = odo.observation_id
      FROM (SELECT DISTINCT ON (observation_document_id) observation_document_id, observation_id FROM observation_documents_observations) odo
      WHERE observation_documents.id = odo.observation_document_id
    SQL
    execute(query)

    drop_table :observation_documents_observations
  end
end

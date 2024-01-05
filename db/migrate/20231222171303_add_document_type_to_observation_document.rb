class AddDocumentTypeToObservationDocument < ActiveRecord::Migration[7.0]
  def up
    add_column :observation_documents, :document_type, :integer, default: 0, null: false
    # 5 is evidence on report in observations table
    # changing Maps from 6 to 5
    query = <<~SQL
      UPDATE observation_documents SET document_type = odo.evidence_type, updated_at = NOW()
      FROM (
        SELECT DISTINCT ON (observation_document_id) observation_document_id, evidence_type
        FROM observation_documents_observations
        INNER JOIN observations ON observations.id = observation_documents_observations.observation_id
        WHERE evidence_type <> 5 AND evidence_type IS NOT NULL
      ) odo
      WHERE observation_documents.id = odo.observation_document_id
    SQL
    execute(query)
    execute("UPDATE observation_documents SET document_type = 5 WHERE document_type = 6")
    execute("UPDATE observations SET evidence_type = 0 WHERE evidence_type <> 5") # set no evidence for all except evidence on report
    execute("UPDATE observations SET evidence_type = 2 WHERE evidence_type = 5") # update for evidence on report
    execute(
      <<~SQL
        UPDATE observations SET evidence_type = 1 WHERE EXISTS (
          SELECT * FROM observation_documents_observations odo
            INNER JOIN observation_documents od ON od.id = odo.observation_document_id
          WHERE observation_id = observations.id AND od.deleted_at IS NULL
        )
      SQL
    ) # update for linked with non deleted documents

    # Testing data after migration
    # I was testing migration correctness with those queries so I will leave them here
    result = execute(
      "SELECT id FROM observations WHERE evidence_type <> 2 AND coalesce(evidence_on_report, '') <> ''"
    )
    raise "Mismatched type when evidence_on_report present" if result.count.positive?
    result = execute(
      <<~SQL
        SELECT id FROM observations WHERE evidence_type <> 1 AND EXISTS (
          SELECT * FROM
            observation_documents_observations odo
          INNER JOIN observation_documents od on od.id = odo.observation_document_id
          WHERE odo.observation_id = observations.id AND od.deleted_at IS NULL
        )
      SQL
    )
    raise "Documents exists for observations with no linked documents" if result.count.positive?
    result = execute(
      <<~SQL
        SELECT id FROM observations WHERE evidence_type = 1 AND NOT EXISTS (
          SELECT * FROM
            observation_documents_observations odo
          INNER JOIN observation_documents od on od.id = odo.observation_document_id
          WHERE odo.observation_id = observations.id AND od.deleted_at IS NULL
        )
      SQL
    )
    raise "No documents when evidence type is 1: #{result.values.flatten}" if result.count.positive?
    result = execute(
      "SELECT id FROM observations WHERE evidence_type = 0 AND validation_status <> 0"
    )
    Rails.logger.debug "No evidence for non created (non drafted) observations #{result.values.flatten}" if result.count.positive?
  end

  def down
    query = <<~SQL
      UPDATE observations SET evidence_type = odo.document_type, updated_at = NOW()
      FROM (
        SELECT DISTINCT ON (observation_id) observation_id, document_type
        FROM observation_documents_observations
        INNER JOIN observation_documents ON observation_documents.id = observation_documents_observations.observation_document_id
      ) odo
      WHERE observations.id = odo.observation_id
    SQL
    execute(query)
    execute("UPDATE observations SET evidence_type = 6 WHERE evidence_type = 5")
    execute("UPDATE observations SET evidence_type = 5 WHERE evidence_type is null and coalesce(evidence_on_report, '') <> ''")
    remove_column :observation_documents, :document_type
  end
end

class AddObservationReportToObservationDocument < ActiveRecord::Migration[7.0]
  def change
    add_reference :observation_documents, :observation_report, foreign_key: true, index: true

    reversible do |dir|
      dir.up do
        execute(
          <<~SQL
            UPDATE observation_documents SET observation_report_id = o.observation_report_id
            FROM observations o
            INNER JOIN observation_documents_observations odo ON odo.observation_id = o.id
            WHERE odo.observation_document_id = observation_documents.id
          SQL
        )
      end
    end
  end
end

class AddObservationDocumentsAndReports < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        rename_table :documents, :observation_documents

        add_column :observation_documents, :observation_id, :integer, index: true
        ObservationDocument.find_each {|x| x.update(observation_id: x.attacheable_id)}
        remove_column :observation_documents, :attacheable_id
        remove_column :observation_documents, :attacheable_type
        remove_column :observation_documents, :document_type

        add_foreign_key :observation_documents, :observations

        create_table :observation_reports do |t|
          t.string :title
          t.datetime :publication_date
          t.string :attachment
          t.integer :user_id
          t.integer :observer_id

          t.timestamps
        end

        add_column :observations, :observation_report_id, :integer
        add_foreign_key :observations, :observation_reports
        add_foreign_key :observation_reports, :users
        add_foreign_key :observation_reports, :observers
      end
    end

  end
end

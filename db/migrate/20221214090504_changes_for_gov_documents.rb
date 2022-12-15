class ChangesForGovDocuments < ActiveRecord::Migration[5.2]
  def change
    remove_column :gov_documents, :current, :boolean, index: true
    remove_column :gov_documents, :reason, :string
    change_column_null :gov_documents, :country_id, false
    change_column_null :gov_documents, :required_gov_document_id, false
    add_column :gov_documents, :attachment, :string

    drop_table :gov_files do |t|
      t.string :attachment
      t.timestamp :deleted_at
      t.timestamps
      t.references :gov_document,
        foreign_key: { on_delete: :cascade },
        index: true
    end
  end
end

class RemoveNoteFromOperatorDocuments < ActiveRecord::Migration[7.2]
  def change
    remove_column :operator_documents, :note, :text
    remove_column :operator_document_histories, :note, :text
  end
end

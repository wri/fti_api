class CopyOperatorDocumentsToHistory < ActiveRecord::Migration[5.0]
  def change
    DocumentMigrationService.new(:documents).call
    remove_column :operator_documents, :current
  end
end

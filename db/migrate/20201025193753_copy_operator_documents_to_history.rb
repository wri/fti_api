class CopyOperatorDocumentsToHistory < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        DocumentMigrationService.new(:documents).call
        remove_column :operator_documents, :current
      end
      dir.down do
        add_column :operator_documents, :current, :boolean, index: true
      end
    end

  end
end
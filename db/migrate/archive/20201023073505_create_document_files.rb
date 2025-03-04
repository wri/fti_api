# rubocop:disable all
class CreateDocumentFiles < ActiveRecord::Migration[5.0]
  def change
    create_table :document_files do |t|
      t.string :attachment
      t.string :file_name

      t.timestamps
    end

    add_column :operator_documents, :document_file_id, :integer
    add_index :operator_documents, :document_file_id
  end
end

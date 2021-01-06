class AddDeletedAtToOperatorDocumentHistory < ActiveRecord::Migration[5.0]
  def change
    add_column :operator_document_histories, :deleted_at, :datetime
    add_index :operator_document_histories, :deleted_at
  end
end

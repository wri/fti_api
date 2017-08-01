class AddDeletedAtForOperatorDocuments < ActiveRecord::Migration[5.0]
  def change
    add_column :operator_documents, :deleted_at, :datetime
    add_index :operator_documents, :deleted_at
  end
end

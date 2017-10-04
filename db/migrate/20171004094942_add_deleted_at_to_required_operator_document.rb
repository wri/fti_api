class AddDeletedAtToRequiredOperatorDocument < ActiveRecord::Migration[5.0]
  def change
    add_column :required_operator_documents, :deleted_at, :datetime
    add_index :required_operator_documents, :deleted_at
  end
end

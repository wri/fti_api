class RemoveIndexFromOperatorDocuments < ActiveRecord::Migration[5.0]
  def change
    change_column_null :operator_documents, :source, false
    change_column_null :operator_documents, :uploaded_by, false
  end
end

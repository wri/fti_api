class ChangeOperatorDocumentUserReference < ActiveRecord::Migration[5.0]
  def change
    add_foreign_key :operator_documents, :users, index: true, on_delete: :nullify
  end
end

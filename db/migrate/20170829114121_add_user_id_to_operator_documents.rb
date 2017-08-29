class AddUserIdToOperatorDocuments < ActiveRecord::Migration[5.0]
  def change
    add_column :operator_documents, :user_id, :integer
  end
end

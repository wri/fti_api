class AddAdminCommentToOperatorDocument < ActiveRecord::Migration[7.0]
  def change
    add_column :operator_documents, :admin_comment, :text
    add_column :operator_document_histories, :admin_comment, :text
  end
end

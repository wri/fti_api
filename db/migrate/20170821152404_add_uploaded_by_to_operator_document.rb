class AddUploadedByToOperatorDocument < ActiveRecord::Migration[5.0]
  def change
    add_column :operator_documents, :uploaded_by, :int
  end
end

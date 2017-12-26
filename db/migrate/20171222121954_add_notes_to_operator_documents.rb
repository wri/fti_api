class AddNotesToOperatorDocuments < ActiveRecord::Migration[5.0]
  def change
    add_column :operator_documents, :note, :text
    add_column :operator_documents, :response_date, :datetime
  end
end

class AddCurrentUniqueIndexToScoreOperatorDocuments < ActiveRecord::Migration[5.0]
  def change
    add_index :score_operator_documents, [:operator_id, :current], unique: true, where: "current"
  end
end

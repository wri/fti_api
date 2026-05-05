class AddInvalidationReasonToOperatorDocumentAnnexes < ActiveRecord::Migration[7.2]
  def change
    add_column :operator_document_annexes, :invalidation_reason, :text
  end
end

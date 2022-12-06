class AddParentToRequiredGovDocumentGroup < ActiveRecord::Migration[5.2]
  def change
    add_reference :required_gov_document_groups, :parent, foreign_key: { to_table: :required_gov_document_groups }
  end
end

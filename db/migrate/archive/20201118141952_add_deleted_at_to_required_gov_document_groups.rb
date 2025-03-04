# rubocop:disable all
class AddDeletedAtToRequiredGovDocumentGroups < ActiveRecord::Migration[5.0]
  def change
    add_column :required_gov_document_groups, :deleted_at, :datetime
    add_index :required_gov_document_groups, :deleted_at
  end
end

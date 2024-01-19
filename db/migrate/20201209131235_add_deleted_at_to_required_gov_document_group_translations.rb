# rubocop:disable all
class AddDeletedAtToRequiredGovDocumentGroupTranslations < ActiveRecord::Migration[5.0]
  def change
    add_column :required_gov_document_group_translations, :deleted_at, :datetime
    add_index :required_gov_document_group_translations, :deleted_at
  end
end

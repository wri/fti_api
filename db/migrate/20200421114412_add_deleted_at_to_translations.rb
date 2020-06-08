class AddDeletedAtToTranslations < ActiveRecord::Migration[5.0]
  def change
    add_column :fmu_translations, :deleted_at, :datetime
    add_index :fmu_translations, :deleted_at

    add_column :required_gov_document_translations, :deleted_at, :datetime
    add_index :required_gov_document_translations, :deleted_at

    add_column :required_operator_document_translations, :deleted_at, :datetime
    add_index :required_operator_document_translations, :deleted_at
  end
end

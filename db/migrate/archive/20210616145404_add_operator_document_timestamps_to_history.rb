# rubocop:disable all
class AddOperatorDocumentTimestampsToHistory < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        add_column :operator_document_histories, :operator_document_updated_at, :datetime, null: true
        add_column :operator_document_histories, :operator_document_created_at, :datetime, null: true
        execute "UPDATE operator_document_histories SET operator_document_updated_at = updated_at"
        execute "UPDATE operator_document_histories SET operator_document_created_at = created_at"
        change_column_null :operator_document_histories, :operator_document_updated_at, false
        change_column_null :operator_document_histories, :operator_document_created_at, false
      end

      dir.down do
        execute "UPDATE operator_document_histories SET updated_at = operator_document_updated_at"
        execute "UPDATE operator_document_histories SET created_at = operator_document_created_at"
        remove_column :operator_document_histories, :operator_document_updated_at, :datetime, null: false
        remove_column :operator_document_histories, :operator_document_created_at, :datetime, null: false
      end
    end
  end
end

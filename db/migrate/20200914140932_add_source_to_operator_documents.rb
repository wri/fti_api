# rubocop:disable all
class AddSourceToOperatorDocuments < ActiveRecord::Migration[5.0]
  def change
    add_column :operator_documents, :source, :integer, default: 1, null: false
    add_column :operator_documents, :source_info, :string
    add_index :operator_documents, :source
  end
end

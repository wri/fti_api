class CreateRequiredOperatorDocuments < ActiveRecord::Migration[5.0]
  def change
    create_table :required_operator_documents do |t|
      t.string :type
      t.integer :required_operator_document_group_id
      t.string :name
      t.integer :country_id

      t.timestamps
    end

    add_foreign_key :required_operator_documents, :required_operator_document_groups
    add_foreign_key :required_operator_documents, :countries
  end
end

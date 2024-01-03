# rubocop:disable all
# frozen_string_literal: true

class AddContractSignatureToDocuments < ActiveRecord::Migration[5.0]
  def change
    add_column :required_operator_documents, :contract_signature, :boolean, default: false, null: false
    add_index :required_operator_documents, :contract_signature

    add_column :operators, :approved, :boolean, default: true, null: false
    add_index :operators, :approved

    add_column :operator_documents, :public, :boolean, default: true, null: false
    add_index :operator_documents, :public

    add_column :operator_document_annexes, :public, :boolean, default: true, null: false
    add_index :operator_document_annexes, :public
  end
end

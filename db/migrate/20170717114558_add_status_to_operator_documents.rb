# frozen_string_literal: true

class AddStatusToOperatorDocuments < ActiveRecord::Migration[5.0]
  def change
    add_column :operator_documents, :status, :integer
    add_column :operator_documents, :operator_id, :integer

    add_foreign_key :operator_documents, :operators
  end
end

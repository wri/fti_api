# frozen_string_literal: true

class CreateOperatorDocument < ActiveRecord::Migration[5.0]
  def change
    create_table :operator_documents   do |t|
      t.string :type
      t.date :expire_date
      t.date :start_date
      t.integer :fmu_id
      t.integer :required_operator_document_id

      t.timestamps
    end

    add_foreign_key :operator_documents, :fmus
    add_foreign_key :operator_documents, :required_operator_documents
  end
end

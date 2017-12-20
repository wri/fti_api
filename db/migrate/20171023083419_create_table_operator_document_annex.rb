# frozen_string_literal: true

class CreateTableOperatorDocumentAnnex < ActiveRecord::Migration[5.0]
  def change
    create_table :operator_document_annexes do |t|
      t.integer :operator_document_id
      t.string :name
      t.date :start_date
      t.date :expire_date
      t.date :deleted_at
      t.integer :status
      t.string :attachment
      t.integer :uploaded_by
      t.integer :user_id


      t.index :deleted_at
      t.index :operator_document_id
      t.index :status
      t.index :user_id
      t.timestamps
    end
  end
end

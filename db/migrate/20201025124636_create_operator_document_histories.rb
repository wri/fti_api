class CreateOperatorDocumentHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :operator_document_histories do |t|
      t.string :type
      t.date :expire_date
      t.integer :status
      t.integer :uploaded_by
      t.text :reason
      t.text :note
      t.datetime :response_date
      t.boolean :public
      t.integer :source
      t.string :source_info

      t.timestamps

      t.references :operator_document, foreign_key: { on_delete: :cascade }, index: true
      t.references :fmu, foreign_key: { on_delete: :cascade }, index: true
      t.references :operator, foreign_key: { on_delete: :cascade }, index: true
      t.references :user, foreign_key: { on_delete: :cascade }, index: true
      t.references :index_odh_on_rod_id, foreign_key: { to_table: :required_operator_documents, on_delete: :cascade }, index: true
      t.references :document_file, foreign_key: { on_delete: :cascade }, index: true

      t.index :type
      t.index :expire_date
      t.index :status
      t.index :response_date
      t.index :public
      t.index :source
    end
  end
end

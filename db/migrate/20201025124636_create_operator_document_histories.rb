class CreateOperatorDocumentHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :operator_document_histories do |t|
      t.string :type
      t.date :expire_date
      t.date :start_date
      t.integer :status
      t.integer :uploaded_by
      t.text :reason
      t.text :note
      t.datetime :response_date
      t.boolean :public
      t.integer :source
      t.string :source_info
      t.integer :fmu_id
      t.integer :document_file_id

      t.timestamps

      t.references :operator_document, foreign_key: { on_delete: :cascade }, index: true
      t.references :operator, foreign_key: { on_delete: :cascade }, index: true
      t.references :user, foreign_key: { on_delete: :nullify }, index: true
      t.references :required_operator_document, foreign_key: { on_delete: :cascade }, index: { name: 'index_odh_on_rod_id_id' }

      t.index :fmu_id
      t.index :document_file_id
      t.index :type
      t.index :expire_date
      t.index :status
      t.index :response_date
      t.index :public
      t.index :source
    end
  end
end

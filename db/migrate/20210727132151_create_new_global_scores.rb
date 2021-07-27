class CreateNewGlobalScores < ActiveRecord::Migration[5.0]
  def change
    create_table :new_global_scores do |t|
      t.date :date, null: false
      t.integer :doc_valid
      t.integer :doc_invalid
      t.integer :doc_pending
      t.integer :doc_not_provided
      t.integer :doc_not_required
      t.integer :doc_expired
      t.integer :fmu_forest_type
      t.string  :document_type

      t.references :country, foreign_key: { on_delete: :cascade }, index: true
      t.references :required_operator_document_group, foreign_key: { on_delete: :cascade }, index: true

      t.index :date
      # t.index [:date, :country_id], unique: true

      t.timestamps
    end
  end
end

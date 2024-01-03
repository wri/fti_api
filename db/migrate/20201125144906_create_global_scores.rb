# rubocop:disable all
class CreateGlobalScores < ActiveRecord::Migration[5.0]
  def change
    create_table :global_scores do |t|
      t.datetime :date, null: false
      t.integer :total_required
      t.jsonb :general_status
      t.jsonb :country_status
      t.jsonb :fmu_status
      t.jsonb :doc_group_status
      t.jsonb :fmu_type_status

      t.references :country, foreign_key: {on_delete: :nullify}, index: true
      t.index :date
      t.index [:date, :country_id], unique: true

      t.timestamps
    end
  end
end

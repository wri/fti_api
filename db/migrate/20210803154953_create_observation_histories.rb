# rubocop:disable all
class CreateObservationHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :observation_histories do |t|
      t.integer :validation_status
      t.integer :observation_type
      t.integer :evidence_type
      t.integer :location_accuracy
      t.integer :severity_level
      t.integer :fmu_forest_type

      t.datetime :observation_updated_at
      t.datetime :observation_created_at
      t.datetime :deleted_at

      t.timestamps

      t.references :observation, foreign_key: {on_delete: :nullify}, index: true
      t.references :fmu, foreign_key: {on_delete: :cascade}, index: true
      t.references :category, foreign_key: {on_delete: :cascade}, index: true
      t.references :subcategory, foreign_key: {on_delete: :cascade}, index: true
      t.references :country, foreign_key: {on_delete: :cascade}, index: true
      t.references :operator, foreign_key: {on_delete: :cascade}, index: true

      t.index :severity_level
      t.index :fmu_forest_type
      t.index :validation_status
    end
  end
end

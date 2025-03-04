# rubocop:disable all
class CreateObservationStatistics < ActiveRecord::Migration[5.0]
  def change
    create_table :observation_statistics do |t|
      t.date :date, null: false

      t.references :country, foreign_key: {on_delete: :cascade}, index: true
      t.references :operator, foreign_key: {on_delete: :cascade}, index: true
      t.references :subcategory, foreign_key: {on_delete: :cascade}, index: true
      t.references :category, foreign_key: {on_delete: :cascade}, index: true
      t.references :fmu, foreign_key: {on_delete: :cascade}, index: true
      t.integer :severity_level
      t.integer :validation_status
      t.integer :fmu_forest_type

      t.integer :total_count, default: 0

      t.index :date

      t.timestamps
    end
  end
end

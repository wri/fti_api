# rubocop:disable all
class CreateOperatorDocumentStatistics < ActiveRecord::Migration[5.0]
  def change
    create_table :operator_document_statistics do |t|
      t.date :date, null: false

      t.references :country, foreign_key: {on_delete: :cascade}, index: true
      t.references :required_operator_document_group,
        foreign_key: {on_delete: :cascade},
        index: {name: "index_operator_document_statistics_rodg"}
      t.integer :fmu_forest_type
      t.string :document_type

      t.integer :valid_count, default: 0
      t.integer :invalid_count, default: 0
      t.integer :pending_count, default: 0
      t.integer :not_provided_count, default: 0
      t.integer :not_required_count, default: 0
      t.integer :expired_count, default: 0

      t.index :date
      t.index [:date, :country_id, :required_operator_document_group_id, :fmu_forest_type, :document_type],
        unique: true,
        name: "index_operator_document_statistics_on_filters"

      t.timestamps
    end
  end
end

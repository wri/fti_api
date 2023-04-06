class CreateObservationReportStatistics < ActiveRecord::Migration[5.0]
  def change
    create_table :observation_report_statistics do |t|
      t.date :date, null: false

      t.references :country, foreign_key: {on_delete: :cascade}, index: true
      t.references :observer, foreign_key: {on_delete: :cascade}, index: true

      t.integer :total_count, default: 0

      t.index :date
      t.index [:date, :country_id, :observer_id],
        unique: true,
        name: "index_observation_report_statistics_on_filters"

      t.timestamps
    end
  end
end

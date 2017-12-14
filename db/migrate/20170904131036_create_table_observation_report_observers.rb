# frozen_string_literal: true

class CreateTableObservationReportObservers < ActiveRecord::Migration[5.0]
  def change
    create_table :observation_report_observers do |t|
      t.integer :observation_report_id
      t.integer :observer_id
      t.timestamps
    end

    add_foreign_key :observation_report_observers, :observers
    add_foreign_key :observation_report_observers, :observation_reports

    remove_column :observation_reports, :observer_id
  end
end

class AddEvidenceOnReportToObservations < ActiveRecord::Migration[5.0]
  def change
    add_column :observations, :evidence_on_report, :string
  end
end

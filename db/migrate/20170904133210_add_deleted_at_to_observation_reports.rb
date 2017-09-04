class AddDeletedAtToObservationReports < ActiveRecord::Migration[5.0]
  def change
    add_column :observation_reports, :deleted_at, :datetime
    add_index :observation_reports, :deleted_at
  end
end

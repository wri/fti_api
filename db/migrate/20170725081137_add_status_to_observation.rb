class AddStatusToObservation < ActiveRecord::Migration[5.0]
  def change
    add_column :observations, :validation_status, :integer, null: false, default: Observation.validation_statuses['Created']
  end
end

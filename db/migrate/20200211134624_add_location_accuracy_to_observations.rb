class AddLocationAccuracyToObservations < ActiveRecord::Migration[5.0]
  def change
    add_column :observations, :location_accuracy, :integer
  end
end

class AddIsPhysicalPlaceToObservations < ActiveRecord::Migration[5.0]
  def change
    add_column :observations, :is_physical_place, :bool, default: true
  end
end

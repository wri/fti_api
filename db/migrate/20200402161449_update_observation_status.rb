class UpdateObservationStatus < ActiveRecord::Migration[5.0]
  def change
    Observation.where(validation_status: 4).destroy_all
  end
end

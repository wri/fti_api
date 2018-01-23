class AddLocationInformationToObservations < ActiveRecord::Migration[5.0]
  def change
    add_column :observations, :location_information, :string
  end
end

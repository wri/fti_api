class AddObservationTypeToObservationStatistic < ActiveRecord::Migration[5.0]
  def change
    add_column :observation_statistics, :observation_type, :integer
  end
end

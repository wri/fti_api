# rubocop:disable all
class AddIsActiveHiddenToObservationStatistics < ActiveRecord::Migration[5.0]
  def change
    add_column :observation_statistics, :hidden, :boolean
    add_column :observation_statistics, :is_active, :boolean
  end
end

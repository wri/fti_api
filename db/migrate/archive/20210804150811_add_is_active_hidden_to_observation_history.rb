# rubocop:disable all
class AddIsActiveHiddenToObservationHistory < ActiveRecord::Migration[5.0]
  def change
    add_column :observation_histories, :hidden, :boolean
    add_column :observation_histories, :is_active, :boolean
    add_index :observation_histories, :hidden
    add_index :observation_histories, :is_active
  end
end

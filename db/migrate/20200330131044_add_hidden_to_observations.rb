# rubocop:disable all
class AddHiddenToObservations < ActiveRecord::Migration[5.0]
  def change
    add_column :observations, :hidden, :boolean, default: false

    add_index :observations, :hidden
  end
end

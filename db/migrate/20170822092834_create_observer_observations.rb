# frozen_string_literal: true

class CreateObserverObservations < ActiveRecord::Migration[5.0]
  def change
    create_table :observer_observations do |t|
      t.integer :observer_id, index: true
      t.integer :observation_id, index: true

      t.timestamps
    end

    remove_column :observations, :observer_id
  end
end

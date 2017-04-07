# frozen_string_literal: true

class CreateSpeciesObservations < ActiveRecord::Migration[5.0]
  def change
    create_table :species_observations do |t|
      t.integer :observation_id, index: true
      t.integer :species_id,     index: true

      t.timestamps
    end
  end
end

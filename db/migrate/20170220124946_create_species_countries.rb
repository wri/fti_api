# frozen_string_literal: true

class CreateSpeciesCountries < ActiveRecord::Migration[5.0]
  def change
    create_table :species_countries do |t|
      t.integer :country_id, index: true
      t.integer :species_id, index: true

      t.timestamps
    end
  end
end

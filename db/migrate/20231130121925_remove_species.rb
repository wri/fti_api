class RemoveSpecies < ActiveRecord::Migration[7.0]
  class Species < ApplicationRecord
    translates :common_name
  end

  def up
    drop_table :species
    drop_table :species_countries
    remove_index :species_observations, :deleted_at
    drop_table :species_observations
    Species.drop_translation_table!
  end

  def down
    create_table :species do |t|
      t.string :name
      t.string :species_class
      t.string :sub_species
      t.string :species_family
      t.string :species_kingdom
      t.string :scientific_name
      t.string :cites_status
      t.integer :cites_id
      t.integer :iucn_status
      t.timestamps
    end
    Species.create_translation_table! common_name: :string
    create_table :species_countries do |t|
      t.references :species, null: false
      t.references :country, null: false
      t.timestamps
    end
    create_table :species_observations do |t|
      t.references :species, null: false
      t.references :observation, null: false
      t.timestamps
      t.datetime :deleted_at
    end
    add_index :species_observations, :deleted_at
  end
end

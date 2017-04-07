# frozen_string_literal: true

class CreateSpecies < ActiveRecord::Migration[5.0]
  def change
    create_table :species do |t|
      t.string  :name
      t.string  :species_class
      t.string  :sub_species
      t.string  :species_family
      t.string  :species_kingdom
      t.string  :scientific_name
      t.string  :cites_status
      t.integer :cites_id
      t.integer :iucn_status

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        Species.create_translation_table!({
          common_name: :string
        })
      end

      dir.down do
        Species.drop_translation_table!
      end
    end
  end
end

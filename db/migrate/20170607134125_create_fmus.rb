# frozen_string_literal: true

class CreateFmus < ActiveRecord::Migration[5.0]
  def change
    create_table :fmus do |t|
      t.integer :country_id, index: true
      t.integer :operator_id, index: true
      t.json :geojson

      t.timestamps
    end

    add_column :observations, :fmu_id, :integer

    add_foreign_key :observations, :fmus

    reversible do |dir|
      dir.up do
        Fmu.create_translation_table!({ name: :string })
      end

      dir.down do
        Fmu.drop_translation_table!
      end
    end
  end
end

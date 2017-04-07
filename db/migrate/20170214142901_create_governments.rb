# frozen_string_literal: true

class CreateGovernments < ActiveRecord::Migration[5.0]
  def change
    create_table :governments do |t|
      t.integer :country_id, index: true

      t.timestamps
    end

    add_foreign_key :observations, :governments

    reversible do |dir|
      dir.up do
        Government.create_translation_table!({
          government_entity: :string,
          details: :text
        })
      end

      dir.down do
        Government.drop_translation_table!
      end
    end
  end
end

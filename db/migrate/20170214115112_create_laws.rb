# frozen_string_literal: true

class CreateLaws < ActiveRecord::Migration[5.0]
  def change
    create_table :laws do |t|
      t.integer :country_id, index: true
      t.string  :vpa_indicator

      t.timestamps
    end

    add_foreign_key :laws, :countries

    reversible do |dir|
      dir.up do
        Law.create_translation_table!({
          legal_reference: :string,
          legal_penalty: :string
        })
      end

      dir.down do
        Law.drop_translation_table!
      end
    end
  end
end

# frozen_string_literal: true

class CreateObservers < ActiveRecord::Migration[5.0]
  def change
    create_table :observers do |t|
      t.string  :observer_type, null: false
      t.integer :country_id,    index: true

      t.timestamps
    end

    add_foreign_key :observations, :observers
    add_foreign_key :observers,    :countries

    reversible do |dir|
      dir.up do
        Observer.create_translation_table!({
          name: :string,
          organization: :string
        })
      end

      dir.down do
        Observer.drop_translation_table!
      end
    end
  end
end

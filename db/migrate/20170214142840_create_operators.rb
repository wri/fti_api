# frozen_string_literal: true

class CreateOperators < ActiveRecord::Migration[5.0]
  def change
    create_table :operators do |t|
      t.string  :operator_type
      t.integer :country_id,    index: true
      t.string  :concession

      t.timestamps
    end

    add_foreign_key :observations, :operators

    reversible do |dir|
      dir.up do
        Operator.create_translation_table!({
          name: :string,
          details: :text
        })
      end

      dir.down do
        Operator.drop_translation_table!
      end
    end
  end
end

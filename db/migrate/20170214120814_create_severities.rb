# frozen_string_literal: true

class CreateSeverities < ActiveRecord::Migration[5.0]
  def change
    create_table :severities do |t|
      t.integer :level
      t.integer :severable_id,   null: false
      t.string  :severable_type, null: false

      t.timestamps
    end

    add_index :severities, ['severable_id', 'severable_type']
    add_index :severities, ['level', 'severable_id', 'severable_type'], unique: true

    reversible do |dir|
      dir.up do
        Severity.create_translation_table!({
          details: :text
        })
      end

      dir.down do
        Severity.drop_translation_table!
      end
    end
  end
end

# frozen_string_literal: true

class CreateAnnexOperators < ActiveRecord::Migration[5.0]
  def change
    create_table :annex_operators do |t|
      t.integer :country_id, index: true

      t.timestamps
    end

    add_foreign_key :annex_operators, :countries

    reversible do |dir|
      dir.up do
        AnnexOperator.create_translation_table!({
          illegality: :string,
          details: :text
        })
      end

      dir.down do
        AnnexOperator.drop_translation_table!
      end
    end
  end
end

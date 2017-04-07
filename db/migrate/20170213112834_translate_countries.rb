# frozen_string_literal: true

class TranslateCountries < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        Country.create_translation_table!({
          name: :string,
          region_name: :string
        }, {
          migrate_data: true,
          remove_source_columns: true
        })
      end

      dir.down do
        Country.drop_translation_table! migrate_data: true
      end
    end
  end
end

# frozen_string_literal: true

class CreateTranslationTableForTools < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        Tool.create_translation_table!(
          {
            name: :string,
            description: :text
          },
          {
            migrate_data: true,
            remove_source_columns: true
          }
        )
      end

      dir.down do
        Tool.drop_translation_table! migrate_data: true
      end
    end
  end
end

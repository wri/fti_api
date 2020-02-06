# frozen_string_literal: true

class CreateTranslationTableForTutorials < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        Tutorial.create_translation_table!({
          name: :string,
          description: :text
        },
        {
          migrate_data: true,
          remove_source_columns: true
        })
      end

      dir.down do
        Tutorial.drop_translation_table! migrate_data: true
      end
    end
  end
end

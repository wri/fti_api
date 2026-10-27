class CreatePageSections < ActiveRecord::Migration[8.0]
  class PageSection < ApplicationRecord
    translates :title, :body
  end

  def change
    create_table :page_sections do |t|
      t.references :page, null: false, foreign_key: {on_delete: :cascade}, index: false
      t.integer :position, null: false
      t.string :code

      t.timestamps

      t.index [:page_id, :position]
    end

    reversible do |dir|
      dir.up do
        PageSection.create_translation_table! title: :string, body: :text
      end

      dir.down do
        PageSection.drop_translation_table!
      end
    end
  end
end

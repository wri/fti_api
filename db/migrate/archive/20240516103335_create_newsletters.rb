class CreateNewsletters < ActiveRecord::Migration[7.1]
  class Newsletter < ApplicationRecord
    translates :title, :short_description
  end

  def change
    create_table :newsletters do |t|
      t.date :date, null: false
      t.string :attachment, null: false
      t.string :image

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        Newsletter.create_translation_table!(
          title: {type: :string, null: false},
          short_description: {type: :text, null: false}
        )
        add_column :newsletter_translations, :title_translated_from, :string
        add_column :newsletter_translations, :short_description_translated_from, :string
      end

      dir.down do
        Newsletter.drop_translation_table!
      end
    end
  end
end

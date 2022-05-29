class CreateAboutPageEntries < ActiveRecord::Migration[5.0]
  def change
    create_table :about_page_entries do |t|
      t.integer :position, null: false, index: true

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        AboutPageEntry.create_translation_table! title: :string, body: :text
      end

      dir.down do
        AboutPageEntry.drop_translation_table!
      end
    end
  end
end

class CreateCountryLinks < ActiveRecord::Migration[5.0]
  def change
    create_table :country_links do |t|
      t.string :url, required: true
      t.boolean :active, default: true
      t.integer :position, required: true

      t.timestamps

      t.references :country,
                   foreign_key: { on_delete: :cascade },
                   index: true
    end

    reversible do |dir|
      dir.up do
        CountryLink.create_translation_table!(
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
        CountryLink.drop_translation_table! migrate_data: true
      end
    end
  end
end

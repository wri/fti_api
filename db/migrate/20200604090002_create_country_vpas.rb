class CreateCountryVpas < ActiveRecord::Migration[5.0]
  def change
    create_table :country_vpas do |t|
      t.string :url, required: true
      t.boolean :active, default: true
      t.integer :position, required: true

      t.timestamps

      t.references :country,
        foreign_key: {on_delete: :cascade},
        index: true
    end

    CountryVpa.create_translation_table!(
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
end

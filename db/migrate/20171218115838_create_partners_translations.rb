class CreatePartnersTranslations < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        Partner.create_translation_table!({ name: { type: :string, null: false },
                                          description: { type: :text }},
                                          { migrate_data: true })
        remove_column :partners, :name
        remove_column :partners, :description
      end

      dir.down do
        add_column :partners, :name
        add_column :partners, :descrition
        Partner.drop_translation_table! migrate_data: true
      end
    end
  end
end

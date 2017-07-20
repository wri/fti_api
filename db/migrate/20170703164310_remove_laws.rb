class RemoveLaws < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        Law.drop_translation_table!
        drop_table :laws
      end

      dir.down do
        create_table :laws do |t|
          t.integer :country_id
          t.string :vpa_indicator
          t.timestamps
        end
        add_foreign_key :laws, :countries

        Law.create_translation_table!({
                                          legal_reference: :string,
                                          legal_penalty: :string
                                      })

      end
    end
  end
end

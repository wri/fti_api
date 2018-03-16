class ChangeContributorsTranslations < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        rename_table :partner_translations, :contributor_translations
        rename_column :contributor_translations, :partner_id, :contributor_id
      end

      dir.down do
        rename_column :partner_translations, :contributor_id, :partner_id
        rename_table :contributor_translations, :partner_translations
      end
    end
  end
end

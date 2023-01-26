class AddOverviewAndVpaOverviewToCountries < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        Country.add_translation_fields! overview: :text, vpa_overview: :text
      end

      dir.down do
        remove_column :country_translations, :overview
        remove_column :country_translations, :vpa_overview
      end
    end
  end
end

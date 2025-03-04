class AddAutomaticTranslationFieldToObservationTranslations < ActiveRecord::Migration[7.0]
  def change
    change_table :observation_translations, bulk: true do |t|
      t.string :details_translated_from
      t.string :concern_opinion_translated_from
      t.string :litigation_status_translated_from
    end
  end
end

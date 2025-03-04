class CreateCountryResponsibleAdmins < ActiveRecord::Migration[7.1]
  def change
    create_table :country_responsible_admins do |t|
      t.references :country, null: false, foreign_key: {on_delete: :cascade}, index: true
      t.references :user, null: false, foreign_key: {on_delete: :cascade}, index: true

      t.index [:country_id, :user_id], unique: true

      t.timestamps
    end
  end
end

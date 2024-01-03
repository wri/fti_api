# rubocop:disable all
class DropRankingOperatorDocuments < ActiveRecord::Migration[5.0]
  def change
    drop_table :ranking_operator_documents do |t|
      t.date :date, null: false
      t.boolean :current, null: false, default: true
      t.integer :position, null: false

      t.references :operator, foreign_key: {on_delete: :cascade}, index: true
      t.references :country, foreign_key: {on_delete: :cascade}, index: true
      t.index :current
      t.index [:position, :country_id, :current], name: "index_rod_on_position_and_country_and_current"

      t.timestamps
    end
  end
end

# frozen_string_literal: true

class CreateGovDocuments < ActiveRecord::Migration[5.0]
  def change
    create_table :gov_documents do |t|
      t.integer :status, null: false
      t.text :reason, null: true
      t.date :start_date, null: true
      t.date :expire_date, null: true
      t.boolean :current, null: false
      t.integer :uploaded_by, null: true
      t.string :link
      t.string :value
      t.string :units
      t.datetime :deleted_at, null: true

      t.timestamps

      t.references :required_gov_document,
        foreign_key: {on_delete: :cascade},
        index: true
      t.references :country,
        foreign_key: {on_delete: :cascade},
        index: true
      t.references :user,
        foreign_key: {on_delete: :cascade},
        index: true
    end
  end
end

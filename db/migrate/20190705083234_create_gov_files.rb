# frozen_string_literal: true

class CreateGovFiles < ActiveRecord::Migration[5.0]
  def change
    create_table :gov_files do |t|
      t.string :attachment
      t.timestamp :deleted_at

      t.timestamps

      t.references :gov_document,
        foreign_key: {on_delete: :cascade},
        index: true
    end
  end
end

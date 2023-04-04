# frozen_string_literal: true

class CreateRequiredGovDocument < ActiveRecord::Migration[5.0]
  def change
    create_table :required_gov_documents do |t|
      t.string :name, null: false
      t.integer :document_type, null: false
      t.integer :valid_period
      t.datetime :deleted_at, null: true

      t.references :required_gov_document_group,
        foreign_key: {on_delete: :cascade},
        index: true, null: true
      t.references :country,
        foreign_key: {on_delete: :cascade},
        index: true, null: true

      t.index :document_type
      t.index :deleted_at

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        RequiredGovDocument.create_translation_table! explanation: :text
      end

      dir.down do
        RequiredGovDocument.drop_translation_table!
      end
    end
  end
end

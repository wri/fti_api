# rubocop:disable all
# frozen_string_literal: true

class CreateRequiredGovDocumentGroup < ActiveRecord::Migration[5.0]
  def change
    create_table :required_gov_document_groups do |t|
      t.integer :position, null: true
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        RequiredGovDocumentGroup.create_translation_table!(
          name: {type: :string, null: false}, description: :text
        )
      end

      dir.down do
        RequiredGovDocumentGroup.drop_translation_table!
      end
    end
  end
end

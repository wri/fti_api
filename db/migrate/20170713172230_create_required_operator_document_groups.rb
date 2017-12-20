# frozen_string_literal: true

class CreateRequiredOperatorDocumentGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :required_operator_document_groups do |t|
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        RequiredOperatorDocumentGroup.create_translation_table!({
                                               name: :string
                                           })
      end

      dir.down do
        RequiredOperatorDocumentGroup.drop_translation_table!
      end
    end
  end
end

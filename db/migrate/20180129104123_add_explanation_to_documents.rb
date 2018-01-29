class AddExplanationToDocuments < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        RequiredOperatorDocument.create_translation_table! explanation: :text
      end

      dir.down do
        RequiredOperatorDocument.drop_translation_table!
      end
    end
  end
end

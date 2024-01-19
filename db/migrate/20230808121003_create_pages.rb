# rubocop:disable all
class CreatePages < ActiveRecord::Migration[7.0]
  def change
    create_table :pages do |t|
      t.string :slug, null: false
      t.timestamps
      t.index :slug, unique: true
    end

    reversible do |dir|
      dir.up do
        Page.create_translation_table! title: :string, body: :text
      end

      dir.down do
        Page.drop_translation_table!
      end
    end
  end
end

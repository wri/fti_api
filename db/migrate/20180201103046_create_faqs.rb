class CreateFaqs < ActiveRecord::Migration[5.0]
  def change
    create_table :faqs do |t|
      t.integer :position, unique: true, null: false
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        Faq.create_translation_table! question: :string, answer: :text
      end

      dir.down do
        Faq.drop_translation_table!
      end
    end
  end
end

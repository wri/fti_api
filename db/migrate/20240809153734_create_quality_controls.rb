class CreateQualityControls < ActiveRecord::Migration[7.1]
  def change
    create_table :quality_controls do |t|
      t.references :reviewable, polymorphic: true, null: false
      t.belongs_to :reviewer, null: false, foreign_key: {to_table: :users}
      t.boolean :passed, null: false, default: false
      t.text :comment
      t.jsonb :metadata, default: {}

      t.timestamps
    end
  end
end

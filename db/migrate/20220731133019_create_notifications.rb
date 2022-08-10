class CreateNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :notifications do |t|
      t.timestamp :last_displayed_at
      t.timestamp :dismissed_at
      t.timestamp :solved_at

      t.references :operator_document, foreign_key: { on_delete: :cascade }, index: true, null: false
      t.references :user, foreign_key: { on_delete: :cascade }, index: true, null: false
      t.references :notification_group, foreign_key: { on_delete: :nullify }, index: true

      t.index :last_displayed_at
      t.index :dismissed_at
      t.index :solved_at

      t.timestamps
    end
  end
end

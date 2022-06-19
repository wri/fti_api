class CreateNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :notifications do |t|
      t.integer  :group, index: true
      t.datetime :last_displayed_at
      t.datetime :dismissed_at
      t.datetime :solved_at
      t.string   :custom_message

      t.timestamps

      t.references :operator_document, foreign_key: { on_delete: :cascade }, index: true, null: false
      t.references :user, foreign_key: { on_delete: :cascade }, index: true, null: false
    end
  end
end

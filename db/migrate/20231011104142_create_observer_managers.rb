class CreateObserverManagers < ActiveRecord::Migration[7.0]
  def change
    create_table :observer_managers do |t|
      t.belongs_to :observer, foreign_key: {on_delete: :cascade}, null: false
      t.belongs_to :user, foreign_key: {on_delete: :cascade}, null: false

      t.index [:user_id, :observer_id], unique: true

      t.timestamps
    end
  end
end

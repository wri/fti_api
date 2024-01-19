# rubocop:disable all
class CreateNotificationGroup < ActiveRecord::Migration[5.0]
  def change
    create_table :notification_groups do |t|
      t.integer :days, null: false
      t.string :name, null: false

      t.timestamps
    end
  end
end

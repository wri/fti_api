# frozen_string_literal: true

class CreateUserObservers < ActiveRecord::Migration[5.0]
  def change
    create_table :user_observers do |t|
      t.integer :observer_id, index: true
      t.integer :user_id,     index: true

      t.timestamps
    end
  end
end

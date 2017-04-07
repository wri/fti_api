# frozen_string_literal: true

class CreateUserPermissions < ActiveRecord::Migration[5.0]
  def change
    create_table :user_permissions do |t|
      t.integer :user_id
      t.integer :user_role,   default: 0, null: false
      t.jsonb   :permissions, default: {}

      t.timestamps
    end

    add_foreign_key :user_permissions, :users
  end
end

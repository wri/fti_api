# frozen_string_literal: true

class CreateAPIKeys < ActiveRecord::Migration[5.0]
  def change
    create_table :api_keys do |t|
      t.string     :access_token
      t.datetime   :expires_at
      t.belongs_to :user, index: true, foreign_key: true
      t.boolean    :is_active, default: true

      t.timestamps
    end

    add_index :api_keys, [:access_token], name: 'index_api_keys_on_access_token', unique: true
  end
end

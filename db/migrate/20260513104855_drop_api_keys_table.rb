class DropAPIKeysTable < ActiveRecord::Migration[7.2]
  def up
    drop_table :api_keys
  end

  def down
    create_table :api_keys, id: :serial do |t|
      t.string :access_token
      t.datetime :expires_at, precision: nil
      t.integer :user_id
      t.boolean :is_active, default: true, null: false
      t.datetime :created_at, precision: nil, null: false
      t.datetime :updated_at, precision: nil, null: false
      t.index [:access_token], name: "index_api_keys_on_access_token", unique: true
      t.index [:user_id], name: "index_api_keys_on_user_id"
    end
    add_foreign_key :api_keys, :users
  end
end

# frozen_string_literal: true

class AddFieldsToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :reset_password_token,   :string
    add_column :users, :reset_password_sent_at, :datetime
    add_column :users, :sign_in_count,          :integer, default: 0, null: false
    add_column :users, :current_sign_in_at,     :datetime
    add_column :users, :last_sign_in_at,        :datetime
    add_column :users, :current_sign_in_ip,     :inet
    add_column :users, :last_sign_in_ip,        :inet

    add_index :users, :reset_password_token, unique: true
  end
end

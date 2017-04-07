# frozen_string_literal: true

class AddFieldsToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :nickname,       :string,  unique: true
    add_column :users, :name,           :string
    add_column :users, :institution,    :string
    add_column :users, :web_url,        :string
    add_column :users, :is_active,      :boolean, default: true
    add_column :users, :deactivated_at, :datetime
  end
end

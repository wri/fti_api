# frozen_string_literal: true

class AddUserToPhotoAndDocument < ActiveRecord::Migration[5.0]
  def change
    add_column :photos,    :user_id, :integer, index: true
    add_column :documents, :user_id, :integer, index: true

    add_foreign_key :photos,    :users
    add_foreign_key :documents, :users
  end
end

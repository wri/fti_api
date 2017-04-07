# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[5.0]
  def change
    create_table :comments do |t|
      t.integer :commentable_id
      t.string  :commentable_type
      t.text    :body
      t.integer :user_id, null: false, index: true

      t.timestamps
    end

    add_foreign_key :comments, :users

    add_index :comments, [:commentable_id, :commentable_type]
  end
end

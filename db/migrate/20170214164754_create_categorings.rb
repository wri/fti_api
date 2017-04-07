# frozen_string_literal: true

class CreateCategorings < ActiveRecord::Migration[5.0]
  def change
    create_table :categorings do |t|
      t.integer :category_id, null: false, index: true
      t.integer :categorizable_id
      t.string  :categorizable_type

      t.timestamps
    end

    add_foreign_key :categorings, :categories

    add_index :categorings, [:category_id, :categorizable_id, :categorizable_type], name: 'category_categorizable_index', unique: true
    add_index :categorings, [:categorizable_id, :categorizable_type],               name: 'categorizable_index'
  end
end

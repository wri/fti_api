# frozen_string_literal: true

class CreateSawmills < ActiveRecord::Migration[5.0]
  def change
    create_table :sawmills do |t|
      t.string :name
      t.float :lat
      t.float :lng
      t.boolean :is_active, null: false, default: true
      t.integer :operator_id, null: false

      t.timestamps
    end

    add_foreign_key :sawmills, :operators
  end
end

# frozen_string_literal: true

class CreatePartners < ActiveRecord::Migration[5.0]
  def change
    create_table :partners do |t|
      t.string :name
      t.string :website
      t.string :logo
      t.integer :priority
      t.integer :category
      t.text :description

      t.timestamps
    end
  end
end

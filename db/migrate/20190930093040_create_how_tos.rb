# rubocop:disable all
# frozen_string_literal: true

class CreateHowTos < ActiveRecord::Migration[5.0]
  def change
    create_table :how_tos do |t|
      t.string :name, null: false
      t.text :description
      t.integer :position

      t.timestamps
    end
  end
end

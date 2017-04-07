# frozen_string_literal: true

class CreateUserOperators < ActiveRecord::Migration[5.0]
  def change
    create_table :user_operators do |t|
      t.integer :operator_id, index: true
      t.integer :user_id,     index: true

      t.timestamps
    end
  end
end

# frozen_string_literal: true

class ChangeUserRelationships < ActiveRecord::Migration[5.0]
  def change
    drop_table :user_observers
    drop_table :user_operators

    add_column :users, :observer_id, :integer
    add_column :users, :operator_id, :integer
  end
end

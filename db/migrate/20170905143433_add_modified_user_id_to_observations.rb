# frozen_string_literal: true

class AddModifiedUserIdToObservations < ActiveRecord::Migration[5.0]
  def change
    add_column :observations, :modified_user_id, :integer
    add_foreign_key :observations, :users, column: :modified_user_id, primary_key: :id
  end
end

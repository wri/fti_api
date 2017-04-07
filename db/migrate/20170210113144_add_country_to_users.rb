# frozen_string_literal: true

class AddCountryToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :country_id, :integer, index: true

    add_foreign_key :users, :countries
  end
end

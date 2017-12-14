# frozen_string_literal: true

class AddCountryToLaws < ActiveRecord::Migration[5.0]
  def change
    add_column :laws, :country_id, :integer

    add_foreign_key :laws, :countries
  end
end

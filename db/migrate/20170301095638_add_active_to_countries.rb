# frozen_string_literal: true

class AddActiveToCountries < ActiveRecord::Migration[5.0]
  def change
    add_column :countries, :is_active, :boolean, null: false, default: false
  end
end

# frozen_string_literal: true

class AddLogoToOperatorsAndObservers < ActiveRecord::Migration[5.0]
  def change
    add_column :observers, :logo, :string
    add_column :operators, :logo, :string
  end
end

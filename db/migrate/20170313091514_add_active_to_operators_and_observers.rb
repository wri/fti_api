# frozen_string_literal: true

class AddActiveToOperatorsAndObservers < ActiveRecord::Migration[5.0]
  def change
    add_column :operators, :is_active, :boolean, default: true
    add_column :observers, :is_active, :boolean, default: true
  end
end

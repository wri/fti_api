# frozen_string_literal: true

class AddCalculationFieldsToOperator < ActiveRecord::Migration[5.0]
  def change
    add_column :operators, :score_absolute, :float
    add_column :operators, :score, :int
    add_column :operators, :obs_per_visit, :float
  end
end

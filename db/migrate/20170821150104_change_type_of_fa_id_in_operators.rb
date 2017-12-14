# frozen_string_literal: true

class ChangeTypeOfFaIdInOperators < ActiveRecord::Migration[5.0]
  def change
    change_column :operators, :fa_id, :string, null: true, unique: true
  end
end

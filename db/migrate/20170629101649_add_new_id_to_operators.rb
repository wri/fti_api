# frozen_string_literal: true

class AddNewIdToOperators < ActiveRecord::Migration[5.0]
  def change
    add_column :operators, :operator_id, :string
  end
end

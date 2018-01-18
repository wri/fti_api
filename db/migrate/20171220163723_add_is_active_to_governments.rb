# frozen_string_literal: true

class AddIsActiveToGovernments < ActiveRecord::Migration[5.0]
  def change
    add_column :governments, :is_active, :boolean, default: true
  end
end

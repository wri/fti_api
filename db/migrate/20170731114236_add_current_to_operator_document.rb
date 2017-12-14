# frozen_string_literal: true

class AddCurrentToOperatorDocument < ActiveRecord::Migration[5.0]
  def change
    add_column :operator_documents, :current, :boolean
  end
end

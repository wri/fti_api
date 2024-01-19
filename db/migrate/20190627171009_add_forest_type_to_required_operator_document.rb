# rubocop:disable all
# frozen_string_literal: true

class AddForestTypeToRequiredOperatorDocument < ActiveRecord::Migration[5.0]
  def change
    add_column :required_operator_documents, :forest_type, :integer
    add_index :required_operator_documents, :forest_type
  end
end

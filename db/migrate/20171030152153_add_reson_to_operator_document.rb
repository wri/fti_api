# frozen_string_literal: true

class AddResonToOperatorDocument < ActiveRecord::Migration[5.0]
  def change
    add_column :operator_documents, :reason, :text
  end
end

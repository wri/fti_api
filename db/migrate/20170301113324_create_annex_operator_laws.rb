# frozen_string_literal: true

class CreateAnnexOperatorLaws < ActiveRecord::Migration[5.0]
  def change
    create_table :annex_operator_laws do |t|
      t.integer :annex_operator_id, index: true
      t.integer :law_id,            index: true

      t.timestamps
    end
  end
end

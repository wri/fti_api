class AddHoldingToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :holding_id, :integer, index: true
    add_foreign_key :users, :holdings, on_delete: :nullify
  end
end

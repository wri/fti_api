class CreateHoldings < ActiveRecord::Migration[5.0]
  def change
    create_table :holdings do |t|
      t.string :name

      t.index :name

      t.timestamps
    end

    add_column :operators, :holding_id, :integer, index: true
    add_foreign_key :operators, :holdings, on_delete: :nullify
  end
end

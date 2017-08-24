class AddUuidToOperators < ActiveRecord::Migration[5.0]
  def change
    add_column :operators, :fa_id, :uuid, null: true, unique: true
  end
end

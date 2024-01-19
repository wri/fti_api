# rubocop:disable all
class AddDeletedAtToFmuOperator < ActiveRecord::Migration[5.0]
  def change
    add_column :fmu_operators, :deleted_at, :datetime
    add_index :fmu_operators, :deleted_at
  end
end

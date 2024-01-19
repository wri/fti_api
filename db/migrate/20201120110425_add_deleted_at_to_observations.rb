# rubocop:disable all
class AddDeletedAtToObservations < ActiveRecord::Migration[5.0]
  def change
    add_column :observations, :deleted_at, :datetime
    add_index :observations, :deleted_at
  end
end

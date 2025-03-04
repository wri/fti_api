# rubocop:disable all
class AddDeletedAtToFmus < ActiveRecord::Migration[5.0]
  def change
    add_column :fmus, :deleted_at, :datetime
    add_index :fmus, :deleted_at
  end
end

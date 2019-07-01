class AddTypeToFmus < ActiveRecord::Migration[5.0]
  def change
    add_column :fmus, :forest_type, :integer, null: false, default: 0
    add_index :fmus, :forest_type
  end
end

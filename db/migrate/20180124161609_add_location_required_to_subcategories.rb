class AddLocationRequiredToSubcategories < ActiveRecord::Migration[5.0]
  def change
    add_column :subcategories, :location_required, :bool, default: true
  end
end

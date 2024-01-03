# rubocop:disable all
class AddPublicInfoToObservers < ActiveRecord::Migration[5.0]
  def change
    add_column :observers, :public_info, :boolean, default: false
  end
end

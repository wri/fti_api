class RemoveLogoFromObservers < ActiveRecord::Migration[7.1]
  def change
    remove_column :observers, :logo, :string
  end
end

class RemovePropertiesFromFmus < ActiveRecord::Migration[5.2]
  def change
    remove_column :fmus, :properties, :jsonb
  end
end

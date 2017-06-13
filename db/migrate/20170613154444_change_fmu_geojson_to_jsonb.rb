class ChangeFmuGeojsonToJsonb < ActiveRecord::Migration[5.0]
  def change
    change_column :fmus, :geojson, :jsonb
  end
end

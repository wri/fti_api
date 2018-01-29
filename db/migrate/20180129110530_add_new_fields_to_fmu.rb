class AddNewFieldsToFmu < ActiveRecord::Migration[5.0]
  def change
    add_column :fmus, :certification_vlc, :bool
    add_column :fmus, :certification_vlo, :bool
    add_column :fmus, :certification_tltv, :bool
  end
end

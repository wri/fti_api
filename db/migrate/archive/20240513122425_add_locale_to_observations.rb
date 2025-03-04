class AddLocaleToObservations < ActiveRecord::Migration[7.1]
  def change
    add_column :observations, :locale, :string
  end
end

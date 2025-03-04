class AddNonConcessionActivityToObservations < ActiveRecord::Migration[7.1]
  def change
    add_column :observations, :non_concession_activity, :boolean, default: false, null: false
  end
end

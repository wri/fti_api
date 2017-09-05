class AddActionsTakenToObservation < ActiveRecord::Migration[5.0]
  def change
    add_column :observations, :actions_taken, :text
  end
end

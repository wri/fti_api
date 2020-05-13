class AddInfoToObservations < ActiveRecord::Migration[5.0]
  def change
    add_column :observations, :admin_comment, :text
    add_column :observations, :monitor_comment, :text
    add_column :observations, :responsible_admin_id, :integer

    add_foreign_key :observations, :users, foreign_key: 'responsible_admin_id'
  end
end

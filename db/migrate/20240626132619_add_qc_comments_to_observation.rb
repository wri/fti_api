class AddQCCommentsToObservation < ActiveRecord::Migration[7.1]
  def change
    rename_column :observations, :admin_comment, :qc2_comment
    add_column :observations, :qc1_comment, :text
  end
end

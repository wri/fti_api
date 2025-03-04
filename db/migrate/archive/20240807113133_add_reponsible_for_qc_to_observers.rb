class AddReponsibleForQCToObservers < ActiveRecord::Migration[7.1]
  def change
    add_reference :observers, :responsible_qc1, index: true, foreign_key: {to_table: :users, on_delete: :nullify}
    rename_column :observers, :responsible_admin_id, :responsible_qc2_id
    add_index :observers, :responsible_qc2_id
  end
end

class RemoveReponsibleUserFromObservers < ActiveRecord::Migration[7.0]
  def change
    remove_reference :observers, :responsible_user, index: true, foreign_key: {to_table: :users, on_delete: :nullify}
  end
end

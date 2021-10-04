class AddResponsibleAdminToObserver < ActiveRecord::Migration[5.0]
  def change
    add_column :observers, :responsible_admin_id, :integer, index: :true
    add_foreign_key :observers, :users, column: :responsible_admin_id, on_delete: :nullify
  end
end

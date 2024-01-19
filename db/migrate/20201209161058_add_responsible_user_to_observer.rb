# rubocop:disable all
class AddResponsibleUserToObserver < ActiveRecord::Migration[5.0]
  def change
    add_column :observers, :responsible_user_id, :integer, index: true
    add_foreign_key :observers, :users, column: :responsible_user_id, on_delete: :nullify
  end
end

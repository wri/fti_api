class RemoveResponsibleAdminFromObservations < ActiveRecord::Migration[7.0]
  def change
    remove_reference :observations, :responsible_admin, index: true
  end
end

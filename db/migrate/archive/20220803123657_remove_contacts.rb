# rubocop:disable all
class RemoveContacts < ActiveRecord::Migration[5.0]
  def change
    drop_table :contacts do |t|
      t.string :name
      t.string :email

      t.timestamps
    end
  end
end

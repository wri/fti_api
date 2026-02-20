class AddShouldChangePasswordToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :should_change_password, :boolean, default: false, null: false
  end
end

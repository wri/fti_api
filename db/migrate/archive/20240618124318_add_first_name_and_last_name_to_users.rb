class AddFirstNameAndLastNameToUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users, bulk: true do |t|
      t.column :first_name, :string
      t.column :last_name, :string
    end
  end
end

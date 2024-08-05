class AddOrganizationAccountToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :organization_account, :boolean, default: false, null: false
  end
end

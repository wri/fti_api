class AddLastActivatedAtToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :last_activated_at, :datetime
  end
end

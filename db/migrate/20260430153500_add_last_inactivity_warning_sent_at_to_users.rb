class AddLastInactivityWarningSentAtToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :last_inactivity_warning_sent_at, :datetime
  end
end

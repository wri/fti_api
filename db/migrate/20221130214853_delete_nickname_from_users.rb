class DeleteNicknameFromUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :nickname
  end
end

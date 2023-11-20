class RemoveWebUrlFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :web_url, :string
  end
end

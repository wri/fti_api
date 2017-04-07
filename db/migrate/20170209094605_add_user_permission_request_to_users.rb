# frozen_string_literal: true

class AddUserPermissionRequestToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :permissions_request,  :integer
    add_column :users, :permissions_accepted, :datetime
  end
end

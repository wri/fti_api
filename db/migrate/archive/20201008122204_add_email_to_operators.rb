# rubocop:disable all
class AddEmailToOperators < ActiveRecord::Migration[5.0]
  def change
    add_column :operators, :email, :string
  end
end

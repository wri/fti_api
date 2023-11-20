class RemoveEmailFromOperators < ActiveRecord::Migration[7.0]
  def change
    remove_column :operators, :email, :string
  end
end

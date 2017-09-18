class AddFieldsToOperator < ActiveRecord::Migration[5.0]
  def change
    add_column :operators, :address, :string
    add_column :operators, :website, :string
  end
end

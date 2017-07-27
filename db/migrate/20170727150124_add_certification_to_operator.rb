class AddCertificationToOperator < ActiveRecord::Migration[5.0]
  def change
    add_column :operators, :certification, :integer
  end
end

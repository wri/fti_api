class RemoveConcessionFromOperators < ActiveRecord::Migration[7.0]
  def change
    remove_column :operators, :concession, :string
  end
end

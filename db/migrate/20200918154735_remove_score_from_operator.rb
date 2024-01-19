# rubocop:disable all
class RemoveScoreFromOperator < ActiveRecord::Migration[5.0]
  def change
    remove_column :operators, :score, :integer
  end
end

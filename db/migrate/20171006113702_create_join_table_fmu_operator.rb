class CreateJoinTableFmuOperator < ActiveRecord::Migration[5.0]
  def change
    create_join_table :fmus, :operators do |t|
      t.boolean :current
      t.date :start_date
      t.date :end_date

      t.index [:fmu_id, :operator_id]
      t.index [:operator_id, :fmu_id]
    end
  end
end

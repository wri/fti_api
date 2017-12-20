# frozen_string_literal: true

class CreateTableFmuOperator < ActiveRecord::Migration[5.0]
  def change
    create_table :fmu_operators do |t|
      t.integer :fmu_id,      null: false
      t.integer :operator_id, null: false
      t.boolean :current,     null: false
      t.date :start_date
      t.date :end_date

      t.index [:fmu_id, :operator_id]
      t.index [:operator_id, :fmu_id]
    end

    Rake::Task['convert:fmu_operator'].invoke

    remove_column :fmus, :operator_id, :integer

  end
end

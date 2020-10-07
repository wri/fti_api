class CreateScoreOperatorObservations < ActiveRecord::Migration[5.0]
  def change
    create_table :score_operator_observations do |t|
      t.date :date, null: false
      t.boolean :current, null: false, default: true
      t.float :score
      t.float :obs_per_visit

      t.references :operator, foreign_key: { on_delete: :cascade }, index: true
      t.index :date
      t.index :current
      t.index [:current, :operator_id]

      t.timestamps
    end

    remove_column :operators, :score_absolute, :float
    remove_column :operators, :obs_per_visit, :float
  end
end

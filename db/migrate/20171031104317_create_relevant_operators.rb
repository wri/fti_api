class CreateRelevantOperators < ActiveRecord::Migration[5.0]
  def change
    create_table :observation_operators do |t|
      t.references :observation, foreign_key: true
      t.references :operator, foreign_key: true

      t.timestamps
    end
  end
end

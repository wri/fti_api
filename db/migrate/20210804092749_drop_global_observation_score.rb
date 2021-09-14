class DropGlobalObservationScore < ActiveRecord::Migration[5.0]
  def up
    drop_table :global_observation_scores
  end

  def down
    create_table :global_observation_scores do |t|
      t.date :date, null: false
      t.integer :obs_total
      t.integer :rep_total
      t.jsonb :rep_country
      t.jsonb :rep_monitor
      t.jsonb :obs_country
      t.jsonb :obs_status
      t.jsonb :obs_producer
      t.jsonb :obs_severity
      t.jsonb :obs_category
      t.jsonb :obs_subcategory
      t.jsonb :obs_fmu
      t.jsonb :obs_forest_type

      t.timestamps
    end
    add_index :global_observation_scores, :date, unique: true
  end
end

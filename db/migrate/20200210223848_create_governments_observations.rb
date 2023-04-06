class CreateGovernmentsObservations < ActiveRecord::Migration[5.0]
  def change
    create_table :governments_observations do |t|
      t.belongs_to :government
      t.belongs_to :observation
      t.timestamps
    end

    add_index :governments_observations, [:government_id, :observation_id], name: "governments_observations_association_index", unique: true
    add_index :governments_observations, [:observation_id, :government_id], name: "observations_governments_association_index", unique: true

    # migrates all government associations for observations to the table for `many to many` associations.
    up_query =
      <<-SQL
  WITH timestamps (created_at, updated_at) as (
     values (NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC')
  )

  INSERT INTO
    governments_observations (government_id, observation_id, created_at, updated_at)
  SELECT
    observations.government_id, observations.id, timestamps.created_at, timestamps.updated_at
  FROM
    observations, timestamps
  WHERE
    observations.government_id IS NOT NULL
      SQL

    # returns back last government associated with observation
    down_query =
      <<-SQL
  UPDATE observations SET government_id = governments_observations.government_id
  FROM (SELECT DISTINCT ON (observation_id) observation_id, government_id FROM governments_observations) governments_observations
  WHERE observations.id = governments_observations.observation_id
      SQL

    reversible do |dir|
      dir.up do
        execute(up_query)

        remove_reference :observations, :government, index: true, foreign_key: true
      end
      dir.down do
        add_reference :observations, :government, index: true, foreign_key: true

        execute(down_query)
      end
    end
  end
end

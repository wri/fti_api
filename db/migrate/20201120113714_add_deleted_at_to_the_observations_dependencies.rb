class AddDeletedAtToTheObservationsDependencies < ActiveRecord::Migration[5.0]
  def change
    add_column :observation_translations, :deleted_at, :datetime
    add_index :observation_translations, :deleted_at

    add_column :species_observations, :deleted_at, :datetime
    add_index :species_observations, :deleted_at

    add_column :governments_observations, :deleted_at, :datetime
    add_index :governments_observations, :deleted_at

    add_column :observer_observations, :deleted_at, :datetime
    add_index :observer_observations, :deleted_at

    add_column :observation_operators, :deleted_at, :datetime
    add_index :observation_operators, :deleted_at

    add_column :photos, :deleted_at, :datetime
    add_index :photos, :deleted_at
  end
end

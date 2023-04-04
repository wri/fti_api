class AddIndexesToTranslations < ActiveRecord::Migration[5.0]
  def change
    # Observations
    add_index :observations, :publication_date
    add_index :observations, :evidence_type
    add_index :observations, :location_accuracy
    add_index :observations, :is_physical_place
    add_index :observations, :responsible_admin_id
    add_index :observations, :created_at
    add_index :observations, :updated_at

    # Law
    add_index :laws, :min_fine
    add_index :laws, :max_fine

    # Severities
    add_index :severities, :level
    add_index :severities, [:level, :id]

    # Users
    add_index :users, :name

    # Countries
    add_index :country_translations, [:name, :country_id]

    # Operators
    add_index :operator_translations, [:name, :operator_id]

    # FMUs
    add_index :fmu_translations, [:name, :fmu_id]

    # Governments
    add_index :government_translations, [:government_entity, :government_id],
      name: "index_gvt_t_on_government_entity_and_government_id"

    # Categories
    add_index :category_translations, [:name, :category_id]

    # Subcategories
    add_index :subcategory_translations, [:name, :subcategory_id]

    # Observers
    add_index :observer_translations, [:name, :observer_id]
  end
end

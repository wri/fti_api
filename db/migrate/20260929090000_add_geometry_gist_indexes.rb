class AddGeometryGistIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :fmus, :geometry, using: :gist, algorithm: :concurrently
    add_index :protected_areas, :geometry, using: :gist, algorithm: :concurrently
  end
end

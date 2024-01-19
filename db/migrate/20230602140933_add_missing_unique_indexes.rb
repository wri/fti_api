# rubocop:disable all
class AddMissingUniqueIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :faqs, :position, unique: true
    add_index :operators, "btrim(lower(name))", unique: true

    remove_index :severities, [:level, :subcategory_id]
    remove_index :severities, [:subcategory_id, :level]
    add_index :severities, [:level, :subcategory_id], unique: true
  end
end

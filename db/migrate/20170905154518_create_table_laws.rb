class CreateTableLaws < ActiveRecord::Migration[5.0]
  def change
    create_table :laws do |t|
      t.text :written_infraction
      t.text :infraction
      t.text :sanctions
      t.integer :min_fine
      t.integer :max_fine
      t.string :penal_servitude
      t.text :other_penalties
      t.text :flegt
      t.integer :subcategory_id

      t.timestamps
    end

    add_foreign_key :laws, :subcategories
    add_column :observations, :law_id, :integer, index: true
    add_foreign_key :observations, :laws

    reversible do |dir|
      dir.up do
        drop_table :laws_subcategories # An old table that shouldn't exist anymore
      end

      dir.down do
        create_table :laws_subcategories
      end
    end
  end
end

class AddLawsToSubcategories < ActiveRecord::Migration[5.0]
  def up
    create_table :country_subcategories do |t|
      t.integer :country_id
      t.integer :subcategory_id

      t.text :law
      t.text :penalty
      t.text :apv

      t.timestamps
    end

    add_foreign_key :country_subcategories, :countries
    add_foreign_key :country_subcategories, :subcategories


  end

  def down
    remove_foreign_key :country_subcategories, :countries
    remove_foreign_key :country_subcategories, :subcategories

    drop_table :country_subcategories
  end
end

class ChangeSubcategoryToText < ActiveRecord::Migration[5.0]
  def self.up
    change_column :subcategory_translations, :name, :text
  end

  def self.down
    change_column :subcategory_translations, :name, :string
  end
end

# frozen_string_literal: true

class RemoveTableCountrySubcategory < ActiveRecord::Migration[5.0]
  def change
    drop_table :country_subcategories
  end
end

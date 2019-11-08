class AddPercentageValidDocumentsToCountry < ActiveRecord::Migration[5.0]
  def change
    add_column :countries, :percentage_valid_documents, :float
  end
end

# rubocop:disable all
class RemovePercentageValidDocumentsFromCountry < ActiveRecord::Migration[5.2]
  def change
    remove_column :countries, :percentage_valid_documents, :float
  end
end

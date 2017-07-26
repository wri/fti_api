class AddPercentageValidDocumentsToOperators < ActiveRecord::Migration[5.0]
  def change
    add_column :operators, :percentage_valid_documents_all, :float
    add_column :operators, :percentage_valid_documents_country, :float
    add_column :operators, :percentage_valid_documents_fmu, :float
  end
end

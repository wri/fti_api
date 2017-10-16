class AddCountryRankingsToOperators < ActiveRecord::Migration[5.0]
  def change
    add_column :operators, :country_doc_rank, :integer
    add_column :operators, :country_operators, :integer
  end
end

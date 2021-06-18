class AddCountryDocRankCountryOperatorsToOperators < ActiveRecord::Migration[5.0]
  def change
    add_column :operators, :country_doc_rank, :integer
    add_column :operators, :country_operators, :integer

    reversible do |dir|
      dir.up do
        RankingOperatorDocument.refresh
      end
    end
  end
end

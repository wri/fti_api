class AddValidPeriodToRequiredOperatorDocument < ActiveRecord::Migration[5.0]
  def change
    add_column :required_operator_documents, :valid_period, :integer
  end
end

class AddCurrencyToLaws < ActiveRecord::Migration[5.0]
  def change
    add_column :laws, :currency, :string
  end
end

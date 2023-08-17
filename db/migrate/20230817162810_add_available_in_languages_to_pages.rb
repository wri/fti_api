class AddAvailableInLanguagesToPages < ActiveRecord::Migration[7.0]
  def change
    add_column :pages, :available_in_languages, :string, array: true
  end
end

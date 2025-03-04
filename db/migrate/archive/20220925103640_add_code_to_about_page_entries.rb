# rubocop:disable all
class AddCodeToAboutPageEntries < ActiveRecord::Migration[5.0]
  def change
    add_column :about_page_entries, :code, :string
  end
end

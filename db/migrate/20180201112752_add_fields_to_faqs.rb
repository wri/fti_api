class AddFieldsToFaqs < ActiveRecord::Migration[5.0]
  def change
    add_column :faqs, :image, :string
  end
end

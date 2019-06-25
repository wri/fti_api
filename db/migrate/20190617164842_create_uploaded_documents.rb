class CreateUploadedDocuments < ActiveRecord::Migration[5.0]
  def change
    create_table :uploaded_documents do |t|
      t.string :name
      t.string :author
      t.string :caption
      t.string :file

      t.timestamps
    end
  end
end

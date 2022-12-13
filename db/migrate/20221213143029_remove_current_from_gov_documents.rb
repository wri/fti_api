class RemoveCurrentFromGovDocuments < ActiveRecord::Migration[5.2]
  def change
    remove_column :gov_documents, :current, :boolean, index: true
  end
end

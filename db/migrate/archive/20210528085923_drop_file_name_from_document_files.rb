# rubocop:disable all
class DropFileNameFromDocumentFiles < ActiveRecord::Migration[5.0]
  def change
    remove_column :document_files, :file_name, :string
  end
end

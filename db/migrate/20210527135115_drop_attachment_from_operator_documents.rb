# rubocop:disable all
class DropAttachmentFromOperatorDocuments < ActiveRecord::Migration[5.0]
  def change
    remove_column :operator_documents, :attachment, :string
  end
end

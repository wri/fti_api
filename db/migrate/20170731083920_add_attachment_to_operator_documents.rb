# frozen_string_literal: true

class AddAttachmentToOperatorDocuments < ActiveRecord::Migration[5.0]
  def change
    add_column :operator_documents, :attachment, :string
  end
end

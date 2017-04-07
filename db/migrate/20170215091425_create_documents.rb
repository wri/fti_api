# frozen_string_literal: true

class CreateDocuments < ActiveRecord::Migration[5.0]
  def change
    create_table :documents do |t|
      t.string  :name
      t.string  :document_type
      t.string  :attachment
      t.integer :attacheable_id
      t.string  :attacheable_type

      t.timestamps
    end

    add_index :documents, [:attacheable_id, :attacheable_type], name: 'documents_attacheable_index'
  end
end

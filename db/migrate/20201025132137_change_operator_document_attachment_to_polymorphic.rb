class ChangeOperatorDocumentAttachmentToPolymorphic < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        add_column :operator_document_annexes, :documentable_id, :integer
        add_column :operator_document_annexes, :documentable_type, :string

        OperatorDocumentAnnex.unscoped.update_all documentable_type: 'OperatorDocument'
        OperatorDocumentAnnex.unscoped.update_all('documentable_id = operator_document_id')

        add_index :operator_document_annexes, :documentable_type
        add_index :operator_document_annexes, :documentable_id
        remove_column :operator_document_annexes, :operator_document_id
      end

      dir.down do
        add_reference :operator_document_annexes, :operator_document_id, foreign_key: {on_delete: :cascade}, index: true
        OperatorDocumentAnnex.unscoped.update_all('operator_document_id = documentable_id')

        remove_column :operator_document_annexes, :documentable_id
        remove_column :operator_document_annexes, :documentable_type
      end
    end
  end
end

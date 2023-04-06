class ChangeOperatorDocumentAttachmentToPolymorphic < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        create_table :annex_documents do |t|
          t.string :documentable_type, null: false
          t.integer :documentable_id, null: false

          t.references :operator_document_annex,
            foreign_key: {on_delete: :cascade}, index: true, null: false
          t.index :documentable_id
          t.index :documentable_type

          t.timestamps
        end

        OperatorDocumentAnnex.unscoped.find_each do |oda|
          AnnexDocument.create! documentable_type: "OperatorDocument",
            documentable_id: oda.operator_document_id,
            operator_document_annex_id: oda.id
        end

        remove_column :operator_document_annexes, :operator_document_id
      end

      dir.down do
        add_column :operator_document_annexes, :operator_document_id, :integer
        AnnexDocument.find_each do |ad|
          OperatorDocumentAnnex.unscoped.find(ad.operator_document_annex_id).update(operator_document_id: ad.documentable_id)
        end

        drop_table :annex_documents
      end
    end
  end
end

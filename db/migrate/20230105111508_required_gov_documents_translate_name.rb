class RequiredGovDocumentsTranslateName < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        RequiredGovDocument.add_translation_fields! name: :string
        migrate_data_up
        PaperTrail.request.disable_model(RequiredGovDocument)
        PaperTrail.request.disable_model(RequiredGovDocument::Translation)
        RequiredGovDocument.find_each { |d| d.save(touch: false) }
        PaperTrail.request.enable_model(RequiredGovDocument)
        PaperTrail.request.enable_model(RequiredGovDocument::Translation)
        remove_column :required_gov_documents, :name
      end

      dir.down do
        add_column :required_gov_documents, :name, :string
        migrate_data_down
        change_column_null :required_gov_documents, :name, false
        remove_column :required_gov_document_translations, :name
      end
    end
  end

  def migrate_data_up
    query = <<~SQL
      UPDATE required_gov_document_translations
      SET name = temp.name
      FROM (
        SELECT d.id, d.name
        FROM required_gov_documents d

      ) as temp
      WHERE required_gov_document_id = temp.id
    SQL

    ActiveRecord::Base.connection.execute query
  end

  def migrate_data_down
    query = <<~SQL
      UPDATE required_gov_documents
      SET name = temp.name
      FROM (
        SELECT t.name, t.required_gov_document_id, t.locale
        FROM required_gov_document_translations t
      ) as temp
      WHERE temp.required_gov_document_id = id AND temp.locale = 'en'
    SQL

    ActiveRecord::Base.connection.execute query
  end
end

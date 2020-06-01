class ChangeRequiredOperatorDocumentFmuType < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        change_column :required_operator_documents, :forest_type,
                      'integer[] USING array[forest_type]::integer[]', default: []
        rename_column :required_operator_documents, :forest_type, :forest_types
        ActiveRecord::Base.connection.execute "UPDATE required_operator_documents set forest_types = '{}' where forest_types = '{NULL}'"
      end

      dir.down do
        rename_column :required_operator_documents, :forest_types, :forest_type
        ActiveRecord::Base.connection.execute('ALTER TABLE "required_operator_documents" alter column "forest_type" drop default')
        ActiveRecord::Base.connection.execute('ALTER TABLE "required_operator_documents" alter column "forest_type" set data type integer using (forest_type[1]::integer)')
      end
    end
  end
end

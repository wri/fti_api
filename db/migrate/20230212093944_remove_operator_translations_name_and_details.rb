class RemoveOperatorTranslationsNameAndDetails < ActiveRecord::Migration[5.2]
  def change
    PaperTrail.request.disable_model(Operator)

    add_column :operators, :name, :string
    add_column :operators, :details, :string

    query = <<~SQL
    UPDATE operators o
      SET name = t.name, details = t.details 
    FROM
      operator_translations t
    WHERE
      o.id = t.operator_id and t.locale = 'en'
    SQL

    ActiveRecord::Base.connection.execute query

    change_column_null :operators, :name, true
    PaperTrail.request.enable_model(Operator)

    drop_table :operator_translations
  end
end
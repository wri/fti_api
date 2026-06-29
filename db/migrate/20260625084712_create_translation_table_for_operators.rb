class CreateTranslationTableForOperators < ActiveRecord::Migration[8.0]
  def change
    PaperTrail.request.disable_model(Operator)
    reversible do |dir|
      dir.up do
        Operator.create_translation_table!({
          details: :string
        }, {
          migrate_data: true,
          remove_source_columns: true
        })
        Operator.find_each do |operator|
          operator.save!(touch: false) # that will copy the translation to all languages
        end
        add_column :operator_translations, :details_translated_from, :string
      end

      dir.down do
        add_column :operators, :details, :string
        migrate_data_down
        Operator.drop_translation_table!
      end
    end
    PaperTrail.request.enable_model(Operator)
  end

  def migrate_data_down
    query = <<~SQL
      UPDATE operators
      SET details = temp.details
      FROM (
        SELECT t.details, t.operator_id, t.locale
        FROM operator_translations t
      ) as temp
      WHERE temp.operator_id = id AND temp.locale = 'en'
    SQL

    ActiveRecord::Base.connection.execute query
  end
end

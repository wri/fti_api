class RemoveFmuNameTranslation < ActiveRecord::Migration[7.1]
  class Fmu < ApplicationRecord
    translates :name
  end

  def up
    # globalize migrate_data for drop_translation_table! does not work
    add_column :fmus, :name, :string
    query = <<~SQL
      UPDATE fmus f
        SET name = t.name
      FROM
        fmu_translations t
      WHERE
        f.id = t.fmu_id and t.locale = 'en'
    SQL
    ActiveRecord::Base.connection.execute query
    Fmu.drop_translation_table!
    change_column_null :fmus, :name, false
  end

  def down
    Fmu.create_translation_table!(
      {name: :string},
      {migrate_data: true, remove_source_columns: true}
    )
  end
end

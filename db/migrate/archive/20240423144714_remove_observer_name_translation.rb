class RemoveObserverNameTranslation < ActiveRecord::Migration[7.1]
  class Observer < ApplicationRecord
    translates :name
  end

  def up
    # globalize migrate_data for drop_translation_table! does not work
    add_column :observers, :name, :string
    query = <<~SQL
      UPDATE observers o
        SET name = t.name
      FROM
        observer_translations t
      WHERE
        o.id = t.observer_id and t.locale = 'en'
    SQL
    ActiveRecord::Base.connection.execute query
    Observer.drop_translation_table!
    change_column_null :observers, :name, false
  end

  def down
    Observer.create_translation_table!(
      {name: :string},
      {migrate_data: true, remove_source_columns: true}
    )
  end
end

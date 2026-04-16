class PaperTrailToJson < ActiveRecord::Migration[7.2]
  def change
    rename_column :versions, :object, :old_object
    rename_column :versions, :object_changes, :old_object_changes

    change_table :versions, bulk: true do |t|
      t.jsonb :object
      t.jsonb :object_changes
    end
  end
end

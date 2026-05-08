class RemoveVersionsOldObjectAndChanges < ActiveRecord::Migration[7.2]
  def change
    change_table :versions, bulk: true do |t|
      t.remove :old_object, type: :text
      t.remove :old_object_changes, type: :text
    end
  end
end

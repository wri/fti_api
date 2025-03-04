# rubocop:disable all
class RemovePhotos < ActiveRecord::Migration[5.1]
  def change
    remove_index :photos, [:attacheable_id, :attacheable_type]
    remove_index :photos, :deleted_at

    drop_table :photos do |t|
      t.belongs_to :user, foreign_key: true

      t.string :name
      t.string :attachment
      t.integer :attacheable_id
      t.string :attacheable_type
      t.datetime :deleted_at

      t.timestamps
    end
  end
end

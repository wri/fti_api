# frozen_string_literal: true

class CreatePhotos < ActiveRecord::Migration[5.0]
  def change
    create_table :photos do |t|
      t.string  :name
      t.string  :attachment
      t.integer :attacheable_id
      t.string  :attacheable_type

      t.timestamps
    end

    add_index :photos, [:attacheable_id, :attacheable_type], name: 'photos_attacheable_index'
  end
end

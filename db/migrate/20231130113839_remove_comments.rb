class RemoveComments < ActiveRecord::Migration[7.0]
  def change
    drop_table :comments do |t|
      t.integer :commentable_id
      t.string :commentable_type
      t.text :body
      t.references :user, foreign_key: {on_delete: :nullify}, index: true

      t.timestamps

      t.index [:commentable_id, :commentable_type], name: "index_comments_on_commentable_id_and_commentable_type"
    end
  end
end

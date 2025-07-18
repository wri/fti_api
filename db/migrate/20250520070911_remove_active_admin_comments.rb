class RemoveActiveAdminComments < ActiveRecord::Migration[7.2]
  def change
    drop_table :active_admin_comments do |t|
      t.string :namespace
      t.text :body
      t.integer :resource_id
      t.string :resource_type
      t.integer :author_id
      t.string :author_type

      t.timestamps

      t.index [:namespace], name: "index_active_admin_comments_on_namespace"
      t.index [:author_type, :author_id], name: "index_active_admin_comments_on_author_type_and_author_id"
      t.index [:resource_type, :resource_id], name: "index_active_admin_comments_on_resource_type_and_resource_id"
    end
  end
end

class CreateTools < ActiveRecord::Migration[5.0]
  def change
    create_table :tools do |t|
      t.string :name, null: false
      t.text :description
      t.integer :position

      t.timestamps
    end
  end
end

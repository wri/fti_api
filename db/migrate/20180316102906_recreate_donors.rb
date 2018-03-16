class RecreateDonors < ActiveRecord::Migration[5.0]
  def self.up
    rename_table :partners, :contributors
    add_column :contributors, :type, :string, required: :true, default: 'Partner'
    add_index :contributors, :type
  end

  def self.down
    remove_index :contributors, :type
    remove_column :contributors, :type
    rename_table :contributors, :partners
  end
end

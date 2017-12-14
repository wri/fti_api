# frozen_string_literal: true

class AddNewFieldsToObservers < ActiveRecord::Migration[5.0]
  def change
    add_column :observers, :address, :string
    add_column :observers, :information_name, :string
    add_column :observers, :information_email, :string
    add_column :observers, :information_phone, :string
    add_column :observers, :data_name, :string
    add_column :observers, :data_email, :string
    add_column :observers, :data_phone, :string
    add_column :observers, :organization_type, :string
  end
end

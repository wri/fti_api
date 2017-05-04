# frozen_string_literal: true

class AddLatLongToObservations < ActiveRecord::Migration[5.0]
  def change
    add_column :observations, :lat, :decimal
    add_column :observations, :lng, :decimal
  end
end

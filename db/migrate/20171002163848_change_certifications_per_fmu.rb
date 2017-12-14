# frozen_string_literal: true

class ChangeCertificationsPerFmu < ActiveRecord::Migration[5.0]
  def change
    remove_column :operators, :certification, :string
    add_column :fmus, :certification_fsc, :boolean, default: false
    add_column :fmus, :certification_pefc, :boolean, default: false
    add_column :fmus, :certification_olb, :boolean, default: false
  end
end

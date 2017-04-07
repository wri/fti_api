# frozen_string_literal: true

class CreateObservations < ActiveRecord::Migration[5.0]
  def change
    create_table :observations do |t|
      t.integer  :annex_operator_id,   index: true
      t.integer  :annex_governance_id, index: true
      t.integer  :severity_id,         index: true
      t.string   :observation_type,    null: false
      t.integer  :user_id
      t.datetime :publication_date
      t.integer  :country_id,          index: true
      t.integer  :observer_id,         index: true
      t.integer  :operator_id,         index: true
      t.integer  :government_id,       index: true
      t.string   :pv
      t.boolean  :is_active,              default: true

      t.timestamps
    end

    add_foreign_key :observations, :countries

    reversible do |dir|
      dir.up do
        Observation.create_translation_table!({
          details: :text,
          evidence: :string,
          concern_opinion: :text,
          litigation_status: :string
        })
      end

      dir.down do
        Observation.drop_translation_table!
      end
    end
  end
end

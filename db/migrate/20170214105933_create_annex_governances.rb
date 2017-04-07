# frozen_string_literal: true

class CreateAnnexGovernances < ActiveRecord::Migration[5.0]
  def change
    create_table :annex_governances do |t|
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        AnnexGovernance.create_translation_table!({
          governance_pillar: :string,
          governance_problem: :text,
          details: :text
        })
      end

      dir.down do
        AnnexGovernance.drop_translation_table!
      end
    end
  end
end

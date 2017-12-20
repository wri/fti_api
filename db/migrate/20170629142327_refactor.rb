# frozen_string_literal: true

class Refactor < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        # Categories
        puts 'Dropping categorings'
        drop_table :categorings

        puts 'Adding type to categories'
        add_column :categories, :category_type, :integer

        # Annex Governance
        puts 'Dropping Annex Governances'
        AnnexGovernance.drop_translation_table!
        drop_table :annex_governances

        # Annex Operator
        puts 'Dropping Annex Operators'
        AnnexOperator.drop_translation_table!
        drop_table :annex_operators

        # Subcategories
        puts 'Creating Subcategories'
        create_table :subcategories do |t|
          t.integer :category_id
          t.integer :subcategory_type

          t.timestamps
        end
        add_foreign_key :subcategories, :categories
        Subcategory.create_translation_table!( { name: :string, details: :text })

        # Annex Operator Laws
        puts 'Dropping Annex Operator Laws'
        drop_table :annex_operator_laws

        # Laws Subcategories
        puts 'Creating Laws Subcategories'
        create_join_table :laws, :subcategories do |t|
          t.index :law_id
          t.index :subcategory_id

          t.timestamps
        end

        # Severities
        puts 'Removing severables'
        remove_column :severities, :severable_id, :integer
        remove_column :severities, :severable_type, :string
        add_column :severities, :subcategory_id, :integer

        puts 'Adding severities to subcategories'
        add_foreign_key :severities, :subcategories

        # Observations
        Observation.find_each do |o|
          o.update_columns(observation_type: (o.observation_type == 'AnnexOperator' ? '0' : '1'))
        end
        change_column :observations, :observation_type, 'integer USING CAST(observation_type AS integer)'

        add_column :observations, :subcategory_id, :integer
        remove_column :observations, :annex_governance_id, :integer
        remove_column :observations, :annex_operator_id, :integer
      end

      dir.down do
        remove_column :observations, :subcategory_id, :integer
        add_column :observations, :annex_governance_id, :integer
        add_column :observations, :annex_operator_id, :integer

        change_column :observations, :observation_type, 'varchar USING CAST(observation_type AS varchar)'
        Observation.find_each do |o|
          o.update_columns(observation_type: (o.observation_type == '0' ? 'AnnexOperator' : 'AnnexGovernance'))
        end

        remove_column :severities, :subcategory_id, :integer
        add_column :severities, :severable_type, :string
        add_column :severities, :severable_id, :integer

        drop_table :laws_subcategories

        create_table :annex_operator_laws do |t|
          t.integer :annex_operator_id, index: true
          t.integer :law_id,            index: true

          t.timestamps
        end

        Subcategory.drop_translation_table!
        drop_table :subcategories

        create_table :annex_operators do |t|
          t.integer :country_id, index: true

          t.timestamps
        end
        add_foreign_key :annex_operators, :countries
        AnnexOperator.create_translation_table!({ illegality: :string, details: :text })

        create_table :annex_governances do |t|
          t.timestamps
        end
        AnnexGovernance.create_translation_table!({
                                                    governance_pillar: :string,
                                                    governance_problem: :text,
                                                    details: :text
                                                  })

        remove_column :categories, :category_type, :string
        create_table :categorings
      end
    end
  end
end

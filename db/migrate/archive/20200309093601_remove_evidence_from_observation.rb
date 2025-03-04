# rubocop:disable all
class RemoveEvidenceFromObservation < ActiveRecord::Migration[5.0]
  def change
    evidence_mapping = ActiveSupport::HashWithIndifferentAccess.new({
      "Document de la compagnie": "Company Documents",
      "Photographies / film": "Photos",
      "Observation sur le terrain": "Other",
      "Company document": "Company Documents",
      "Images satellites": "Maps",
      "Government document": "Government Documents",
      "Image satellite / carte": "Maps",
      "Satellite imagery/map": "Maps",
      "Third party report": "Other",
      "Third party document": "Other",
      "Mandated IM report": "Other",
      "Not specified": "Other",
      "Photographs/film": "Photos",
      Testimony: "Testimony from local communities",
      "Statistiques officielles": "Government Documents",
      "Document officiel": "Government Documents",
      "Document de la société": "Company Documents",
      "Non précisé": "Other",
      "Rapport de tiers": "Other",
      "Field observation": "Other",
      "Official document": "Government Documents",
      Multiple: "Other",
      "Données commerciales": "Other",
      "Trade data": "Other",
      "Government statistics": "Government Documents"
    })

    reversible do |dir|
      dir.up do
        evidence_mapping.each do |key, val|
          query =
            <<~SQL
              UPDATE observations
              SET evidence_type = '#{Observation.evidence_types[val.to_sym]}'
              FROM observation_translations
              WHERE observations.id = observation_translations.observation_id 
                AND observation_translations.locale = 'en' 
                AND observation_translations.evidence = '#{key}'
            SQL
          ActiveRecord::Base.connection.execute(query)
        end

        remove_column :observation_translations, :evidence
      end

      dir.down do
        add_column :observation_translations, :evidence, :string

        Observation.find_each do |obs|
          ActiveRecord::Base.connection.execute("
          UPDATE observation_translations
          set evidence = '#{obs.evidence_type}'
          where observation_id = #{obs.id}")
        end
      end
    end
  end
end

# rubocop:disable all
class AddEvidenceOnReportToTranslatedFields < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        Observation.add_translation_fields! evidence_on_report: :string
        add_column :observation_translations, :evidence_on_report_translated_from, :string
        migrate_data_up
        remove_column :observations, :evidence_on_report
      end

      dir.down do
        add_column :observations, :evidence_on_report, :string
        migrate_data_down
        remove_column :observation_translations, :evidence_on_report
        remove_column :observation_translations, :evidence_on_report_translated_from
      end
    end
  end

  def migrate_data_up
    ActiveRecord::Base.connection.execute <<~SQL
      UPDATE observation_translations
      SET evidence_on_report = temp.evidence_on_report
      FROM (
        SELECT id, evidence_on_report
        FROM observations
      ) AS temp
      WHERE observation_translations.observation_id = temp.id
    SQL
  end

  def migrate_data_down
    ActiveRecord::Base.connection.execute <<~SQL
      UPDATE observations
      SET evidence_on_report = temp.evidence_on_report
      FROM (
        SELECT evidence_on_report, observation_id
        FROM observation_translations
        WHERE locale = 'en'
      ) AS temp
      WHERE temp.observation_id = observations.id
    SQL
  end
end

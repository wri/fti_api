PAPER_TRAIL_CLEAN_CONFIG = [
  {
    item_type: "Operator",
    stripped_fields: %w[
      percentage_valid_documents_all
      percentage_valid_documents_fmu
      percentage_valid_documents_country
      country_doc_rank
      country_operators
      score_absolute
      obs_per_visit
      updated_at
    ]
  },
  {
    item_type: "Fmu",
    stripped_fields: %w[geometry updated_at]
  }
].freeze

namespace :paper_trail do
  desc "Clean versions for all models - delete where only ignored fields changed, strip those fields from the rest. Set FOR_REAL=true to apply. Optionally filter with ITEM_TYPE=Foo."
  task clean_up: :environment do
    for_real = ENV["FOR_REAL"] == "true"
    filter_item_type = ENV["ITEM_TYPE"]

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"
    puts "Filtering to item_type=#{filter_item_type}" if filter_item_type

    configs = PAPER_TRAIL_CLEAN_CONFIG
    configs = configs.select { |c| c[:item_type] == filter_item_type } if filter_item_type

    configs.each do |config|
      item_type = config[:item_type]
      stripped_fields = config[:stripped_fields]
      ids_to_delete = []
      ids_to_strip = []

      PaperTrail::Version.where(event: "update", item_type: item_type).find_each do |version|
        next if version.object_changes.blank?

        changes = version.changeset
        next unless (changes.keys & stripped_fields).any?

        if (changes.keys - stripped_fields).empty?
          ids_to_delete << version.id
        else
          ids_to_strip << version.id
        end
      end

      puts "\n#{item_type}:"
      puts "  #{ids_to_delete.size} versions to delete (only ignored fields changed)"
      puts "  #{ids_to_strip.size} versions to strip ignored fields from"

      next unless for_real

      if ids_to_delete.any?
        PaperTrail::Version.where(id: ids_to_delete).delete_all
        puts "  Deleted."
      end

      if ids_to_strip.any?
        PaperTrail::Version.where(id: ids_to_strip).find_each do |version|
          changes = version.changeset
          stripped_fields.each { |f| changes.delete(f) }
          version.update_column(:object_changes, PaperTrail.serializer.dump(changes))
        end
        puts "  Stripped."
      end
    end
  end

  desc "Remove duplicate versions with identical object_changes created within 3 seconds of each other. Set FOR_REAL=true to apply."
  task deduplicate: :environment do
    for_real = ENV["FOR_REAL"] == "true"

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"

    ids_to_delete = ActiveRecord::Base.connection.select_values(<<~SQL)
      WITH lagged AS (
        SELECT id,
               object_changes,
               created_at,
               LAG(object_changes) OVER (PARTITION BY item_type, item_id ORDER BY created_at, id) AS prev_object_changes,
               LAG(created_at)     OVER (PARTITION BY item_type, item_id ORDER BY created_at, id) AS prev_created_at
        FROM versions
        WHERE event = 'update'
      )
      SELECT id FROM lagged
      WHERE object_changes = prev_object_changes
        AND EXTRACT(EPOCH FROM (created_at - prev_created_at)) <= 3
    SQL

    puts "Found #{ids_to_delete.size} duplicate versions."

    if for_real && ids_to_delete.any?
      PaperTrail::Version.where(id: ids_to_delete).delete_all
      puts "Deleted."
    end
  end
end

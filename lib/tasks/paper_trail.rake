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
    stripped_fields: %w[geometry properties updated_at]
  }
].freeze

PAPER_TRAIL_MERGE_TRANSLATIONS_CONFIG = [
  {
    item_type: "Fmu",
    translated_fields: %w[name]
  },
  {
    item_type: "Operator",
    translated_fields: %w[name details]
  }
].freeze

namespace :paper_trail do
  desc "Run all paper_trail cleanup tasks in order. Set FOR_REAL=true to apply."
  task clean_up_all: %i[strip_fmu_geojson_properties clean_up deduplicate]

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

  desc "Merge Translation versions (locale: en) into parent model versions, then delete all translation versions. Set FOR_REAL=true to apply. Optionally filter with ITEM_TYPE=Foo."
  task merge_old_translations: :environment do
    for_real = ENV["FOR_REAL"] == "true"
    filter_item_type = ENV["ITEM_TYPE"]

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"
    puts "Filtering to item_type=#{filter_item_type}" if filter_item_type

    configs = PAPER_TRAIL_MERGE_TRANSLATIONS_CONFIG
    configs = configs.select { |c| c[:item_type] == filter_item_type } if filter_item_type

    configs.each do |config|
      item_type = config[:item_type]
      translated_fields = config[:translated_fields]
      translation_item_type = "#{item_type}::Translation"
      foreign_key = "#{item_type.downcase}_id"

      new_versions = []
      skipped = 0

      translation_versions = PaperTrail::Version.where(item_type: translation_item_type, locale: "en", event: "update")

      translation_versions.find_each do |version|
        parent_id = if version.object.present?
          PaperTrail.serializer.load(version.object)[foreign_key]
        elsif version.object_changes.present?
          PaperTrail.serializer.load(version.object_changes)[foreign_key]&.last
        end

        unless parent_id
          skipped += 1
          next
        end

        relevant_changes = PaperTrail.serializer.load(version.object_changes).slice(*translated_fields)

        next if relevant_changes.empty?

        new_versions << {
          item_type: item_type,
          item_id: parent_id,
          event: version.event,
          whodunnit: version.whodunnit,
          object_changes: PaperTrail.serializer.dump(relevant_changes),
          created_at: version.created_at
        }
      end

      total = PaperTrail::Version.where(item_type: translation_item_type).count
      total_update_en = PaperTrail::Version.where(item_type: translation_item_type, locale: "en", event: "update").count
      puts "\n#{item_type}:"
      puts "  #{translation_item_type} versions total: #{total}"
      puts "  #{translation_item_type} versions locale en and event update: #{total_update_en}"
      puts "  #{new_versions.size} to convert to #{item_type} versions"
      puts "  #{skipped} skipped due to missing #{foreign_key}"

      next unless for_real

      PaperTrail::Version.insert_all(new_versions) if new_versions.any?
      puts "  Created #{new_versions.size} #{item_type} versions."

      PaperTrail::Version.where(item_type: translation_item_type).delete_all
      puts "  Deleted #{total} #{translation_item_type} versions."
    end
  end

  desc "Strip geojson['properties'] from Fmu version object_changes. Deletes version if geojson is the only change and becomes identical after stripping. Set FOR_REAL=true to apply."
  task strip_fmu_geojson_properties: :environment do
    for_real = ENV["FOR_REAL"] == "true"

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"

    ids_to_delete = []
    ids_to_update = {}

    PaperTrail::Version.where(item_type: "Fmu", event: "update").find_each do |version|
      next if version.object_changes.blank?

      changes = PaperTrail.serializer.load(version.object_changes)
      next unless changes.key?("geojson")

      old_geojson, new_geojson = changes["geojson"]
      old_geojson = JSON.parse(old_geojson) if old_geojson.is_a?(String)
      new_geojson = JSON.parse(new_geojson) if new_geojson.is_a?(String)
      old_geojson&.delete("properties")
      new_geojson&.delete("properties")

      if old_geojson == new_geojson
        changes.delete("geojson")
      else
        changes["geojson"] = [old_geojson&.to_json, new_geojson&.to_json]
      end

      if (changes.keys - %w[updated_at]).empty?
        ids_to_delete << version.id
      else
        ids_to_update[version.id] = PaperTrail.serializer.dump(changes)
      end
    end

    puts "#{ids_to_delete.size} versions to delete (geojson-only change, properties was the only diff)"
    puts "#{ids_to_update.size} versions to update (strip properties from geojson)"

    next unless for_real

    PaperTrail::Version.where(id: ids_to_delete).delete_all if ids_to_delete.any?
    puts "Deleted #{ids_to_delete.size} versions."

    ids_to_update.each do |id, object_changes|
      PaperTrail::Version.where(id: id).update_all(object_changes: object_changes)
    end
    puts "Updated #{ids_to_update.size} versions."
  end
end
